import frappe


def _get_current_employee():
	employee = frappe.db.get_value("Employee", {"user_id": frappe.session.user}, "name")
	if not employee:
		frappe.throw(frappe._("No employee record linked to the current user"))
	return employee


@frappe.whitelist()
def get_regularizations(employee=None, status=None, from_date=None, to_date=None):
	filters = {}
	if employee:
		filters["employee"] = employee
	if status:
		filters["status"] = status
	if from_date and to_date:
		filters["attendance_date"] = ["between", [from_date, to_date]]
	elif from_date:
		filters["attendance_date"] = [">=", from_date]
	elif to_date:
		filters["attendance_date"] = ["<=", to_date]

	records = frappe.get_list(
		"Zeus Attendance Regularization",
		filters=filters,
		fields=[
			"name", "employee", "attendance_date", "regularization_type",
			"status", "reason", "approver", "linked_attendance",
		],
		order_by="attendance_date desc",
	)
	return records


@frappe.whitelist()
def get_regularization(reg_name):
	if not frappe.db.exists("Zeus Attendance Regularization", reg_name):
		frappe.throw(frappe._("Regularization request {0} not found").format(reg_name), frappe.DoesNotExistError)

	return frappe.get_doc("Zeus Attendance Regularization", reg_name).as_dict()


@frappe.whitelist()
def create_regularization(attendance_date, regularization_type, reason,
						requested_check_in=None, requested_check_out=None, employee=None):
	if not employee:
		employee = _get_current_employee()

	doc = frappe.get_doc({
		"doctype": "Zeus Attendance Regularization",
		"employee": employee,
		"attendance_date": attendance_date,
		"regularization_type": regularization_type,
		"reason": reason,
		"status": "Pending",
		"requested_check_in": requested_check_in,
		"requested_check_out": requested_check_out,
	})
	doc.insert()
	return doc.as_dict()


@frappe.whitelist()
def approve_regularization(reg_name, approver_remarks=None):
	if not frappe.db.exists("Zeus Attendance Regularization", reg_name):
		frappe.throw(frappe._("Regularization request {0} not found").format(reg_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Zeus Attendance Regularization", reg_name)

	if doc.status != "Pending":
		frappe.throw(frappe._("Only Pending requests can be approved. Current status: {0}").format(doc.status))

	approver_employee = _get_current_employee()
	doc.status = "Approved"
	doc.approver = approver_employee
	doc.approver_remarks = approver_remarks
	doc.save()
	return doc.as_dict()


@frappe.whitelist()
def reject_regularization(reg_name, approver_remarks=None):
	if not frappe.db.exists("Zeus Attendance Regularization", reg_name):
		frappe.throw(frappe._("Regularization request {0} not found").format(reg_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Zeus Attendance Regularization", reg_name)

	if doc.status != "Pending":
		frappe.throw(frappe._("Only Pending requests can be rejected. Current status: {0}").format(doc.status))

	approver_employee = _get_current_employee()
	doc.status = "Rejected"
	doc.approver = approver_employee
	doc.approver_remarks = approver_remarks
	doc.save()
	return doc.as_dict()
