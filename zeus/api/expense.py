import frappe
from frappe.utils import cint, flt, getdate, today

from zeus.api.utils import get_current_employee, get_accessible_employees, is_unrestricted, require_doctype

CATEGORY_ALIASES = {
	"travel": "Travel",
	"food": "Food",
	"food & meals": "Food",
	"food_and_meals": "Food",
	"accommodation": "Accommodation",
	"communication": "Communication",
	"equipment": "Equipment",
	"other": "Other",
}


def _normalize_category(category):
	if not category:
		return "Other"
	key = str(category).strip().lower().replace("-", "_")
	return CATEGORY_ALIASES.get(key, str(category).strip().title())


def _map_claim_status(claim):
	approval = (claim.get("approval_status") or "").strip()
	docstatus = cint(claim.get("docstatus"))
	if approval == "Rejected" or (claim.get("status") or "") == "Rejected":
		return "rejected"
	if approval == "Approved":
		return "approved"
	if docstatus == 1:
		return "submitted"
	return "draft"


def _expense_account(company):
	account = frappe.db.get_value(
		"Account",
		{"account_type": "Expense Account", "company": company, "is_group": 0, "disabled": 0},
		"name",
	)
	if not account:
		frappe.throw(frappe._("No expense account found for company {0}").format(company))
	return account


def _get_or_create_expense_type(label, company, expense_account):
	if frappe.db.exists("Expense Claim Type", label):
		return label

	doc = frappe.get_doc(
		{
			"doctype": "Expense Claim Type",
			"expense_type": label,
		}
	)
	meta = frappe.get_meta("Expense Claim Type")
	if meta.has_field("accounts") and company and expense_account:
		doc.append("accounts", {"company": company, "default_account": expense_account})
	doc.insert(ignore_permissions=True)
	return doc.name


def _account_for_type(expense_type, company, fallback):
	if not frappe.db.exists("DocType", "Expense Claim Type"):
		return fallback
	if not frappe.db.exists("Expense Claim Type", expense_type):
		return fallback
	if not frappe.db.exists("DocType", "Expense Claim Account"):
		return fallback
	meta = frappe.get_meta("Expense Claim Type")
	if not meta.has_field("accounts"):
		return fallback
	account = frappe.db.get_value(
		"Expense Claim Account",
		{"parent": expense_type, "company": company},
		"default_account",
	)
	return account or fallback


def _claim_fields():
	fields = [
		"name",
		"employee",
		"posting_date",
		"total_claimed_amount",
		"approval_status",
		"docstatus",
		"status",
		"remark",
	]
	meta = frappe.get_meta("Expense Claim")
	if meta.has_field("zeus_task"):
		fields.append("zeus_task")
	if meta.has_field("zeus_visit_log"):
		fields.append("zeus_visit_log")
	return fields


def _has_receipt(claim_name, first_row=None):
	if first_row:
		for key in ("supporting_document", "attach_receipt"):
			if first_row.get(key):
				return True
	return bool(
		frappe.db.exists(
			"File",
			{"attached_to_doctype": "Expense Claim", "attached_to_name": claim_name, "is_folder": 0},
		)
	)


def _serialize_claim(claim):
	details = frappe.get_all(
		"Expense Claim Detail",
		filters={"parent": claim.name},
		fields=["description", "expense_type", "amount", "expense_date", "supporting_document"]
		if frappe.get_meta("Expense Claim Detail").has_field("supporting_document")
		else ["description", "expense_type", "amount", "expense_date"],
		order_by="idx asc",
	)
	first = details[0] if details else {}
	title = first.get("description") or claim.name
	return {
		"name": claim.name,
		"title": title,
		"category": first.get("expense_type"),
		"amount": flt(claim.total_claimed_amount),
		"date": claim.posting_date,
		"status": _map_claim_status(claim),
		"approval_status": claim.approval_status,
		"docstatus": cint(claim.docstatus),
		"linked_task": claim.get("zeus_task"),
		"linked_visit_log": claim.get("zeus_visit_log"),
		"notes": claim.remark,
		"has_receipt": _has_receipt(claim.name, first),
		"lines": details,
	}


def count_pending_expenses(employee):
	if not frappe.db.exists("DocType", "Expense Claim"):
		return 0
	claims = frappe.get_all(
		"Expense Claim",
		filters={"employee": employee, "docstatus": ["<", 2]},
		fields=["approval_status", "status", "docstatus"],
	)
	return sum(1 for c in claims if _map_claim_status(c) in ("draft", "submitted"))


def _assert_claim_access(claim):
	if is_unrestricted():
		return
	accessible = get_accessible_employees()
	if accessible is None:
		return
	if claim.employee not in accessible:
		frappe.throw(frappe._("Not permitted"), frappe.PermissionError)


@frappe.whitelist()
def get_my_expenses(status=None, from_date=None, to_date=None):
	require_doctype("Expense Claim")
	employee = get_current_employee()
	filters = {"employee": employee, "docstatus": ["<", 2]}
	if from_date and to_date:
		filters["posting_date"] = ["between", [from_date, to_date]]
	elif from_date:
		filters["posting_date"] = [">=", from_date]
	elif to_date:
		filters["posting_date"] = ["<=", to_date]

	claims = frappe.get_all(
		"Expense Claim",
		filters=filters,
		fields=_claim_fields(),
		order_by="posting_date desc",
	)
	results = [_serialize_claim(c) for c in claims]
	if status:
		wanted = str(status).strip().lower()
		results = [r for r in results if r["status"] == wanted]
	return results


@frappe.whitelist()
def create_expense(
	title,
	amount,
	expense_date=None,
	category="Other",
	notes=None,
	receipt=None,
	linked_task=None,
	linked_visit_log=None,
	submit=0,
):
	"""Create a single-line Expense Claim for the session employee.

	`receipt` should be a file URL returned by `POST /api/method/upload_file`.
	"""
	require_doctype("Expense Claim")
	employee = get_current_employee()
	emp = frappe.get_cached_doc("Employee", employee)
	company = emp.company
	if not company:
		frappe.throw(frappe._("Employee {0} has no company set").format(employee))

	expense_date = getdate(expense_date or today())
	label = _normalize_category(category)
	expense_account = _expense_account(company)
	expense_type = label
	if frappe.db.exists("DocType", "Expense Claim Type"):
		expense_type = _get_or_create_expense_type(label, company, expense_account)
		expense_account = _account_for_type(expense_type, company, expense_account)

	doc = frappe.get_doc(
		{
			"doctype": "Expense Claim",
			"employee": employee,
			"company": company,
			"posting_date": expense_date,
			"remark": notes,
		}
	)
	meta = frappe.get_meta("Expense Claim")
	if emp.expense_approver and meta.has_field("expense_approver"):
		doc.expense_approver = emp.expense_approver
	if linked_task and meta.has_field("zeus_task"):
		doc.zeus_task = linked_task
	if linked_visit_log and meta.has_field("zeus_visit_log"):
		doc.zeus_visit_log = linked_visit_log

	row = {
		"expense_date": expense_date,
		"expense_type": expense_type,
		"description": title,
		"amount": flt(amount),
		"expense_account": expense_account,
	}
	detail_meta = frappe.get_meta("Expense Claim Detail")
	if receipt and detail_meta.has_field("supporting_document"):
		row["supporting_document"] = receipt
	doc.append("expenses", row)
	doc.insert(ignore_permissions=True)

	if receipt:
		_attach_receipt(doc, receipt)

	if cint(submit):
		doc.submit()

	return _serialize_claim(frappe.get_doc("Expense Claim", doc.name))


def _attach_receipt(doc, receipt):
	existing = frappe.db.exists(
		"File",
		{"file_url": receipt, "attached_to_doctype": "Expense Claim", "attached_to_name": doc.name},
	)
	if existing:
		return
	file_name = frappe.db.get_value("File", {"file_url": receipt}, "name")
	if file_name:
		file_doc = frappe.get_doc("File", file_name)
		if not file_doc.attached_to_name:
			file_doc.attached_to_doctype = "Expense Claim"
			file_doc.attached_to_name = doc.name
			file_doc.save(ignore_permissions=True)
			return
	# Copy-attach so the claim owns a File row even if the original is unattached elsewhere
	frappe.get_doc(
		{
			"doctype": "File",
			"file_url": receipt,
			"attached_to_doctype": "Expense Claim",
			"attached_to_name": doc.name,
			"is_private": 1,
		}
	).insert(ignore_permissions=True)


@frappe.whitelist()
def submit_expense(claim_name):
	require_doctype("Expense Claim")
	if not frappe.db.exists("Expense Claim", claim_name):
		frappe.throw(frappe._("Expense Claim {0} not found").format(claim_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Expense Claim", claim_name)
	_assert_claim_access(doc)
	if cint(doc.docstatus) != 0:
		frappe.throw(frappe._("Expense Claim {0} is already submitted").format(claim_name))
	doc.submit()
	return _serialize_claim(frappe.get_doc("Expense Claim", doc.name))
