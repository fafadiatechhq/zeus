import frappe


def _get_current_employee():
	employee = frappe.db.get_value("Employee", {"user_id": frappe.session.user}, "name")
	if not employee:
		frappe.throw(frappe._("No employee record linked to the current user"))
	return employee


@frappe.whitelist()
def get_visit_logs(employee=None, customer=None, site=None, from_date=None, to_date=None):
	filters = {}
	if employee:
		filters["employee"] = employee
	if customer:
		filters["customer"] = customer
	if site:
		filters["site"] = site
	if from_date:
		filters["visit_datetime"] = [">=", from_date]
	if from_date and to_date:
		filters["visit_datetime"] = ["between", [from_date, to_date]]
	elif to_date:
		filters["visit_datetime"] = ["<=", to_date]

	logs = frappe.get_list(
		"Zeus Visit Log",
		filters=filters,
		fields=[
			"name", "employee", "visit_datetime", "customer", "site",
			"purpose", "latitude", "longitude", "linked_task",
		],
		order_by="visit_datetime desc",
	)
	return logs


@frappe.whitelist()
def get_visit_log(log_name):
	if not frappe.db.exists("Zeus Visit Log", log_name):
		frappe.throw(frappe._("Visit Log {0} not found").format(log_name), frappe.DoesNotExistError)

	return frappe.get_doc("Zeus Visit Log", log_name).as_dict()


@frappe.whitelist()
def create_visit_log(visit_datetime, customer=None, site=None, purpose=None,
					notes=None, photo=None, latitude=None, longitude=None,
					linked_task=None, employee=None):
	if not employee:
		employee = _get_current_employee()

	doc = frappe.get_doc({
		"doctype": "Zeus Visit Log",
		"employee": employee,
		"visit_datetime": visit_datetime,
		"customer": customer,
		"site": site,
		"purpose": purpose,
		"notes": notes,
		"photo": photo,
		"latitude": float(latitude) if latitude else None,
		"longitude": float(longitude) if longitude else None,
		"linked_task": linked_task,
	})
	doc.insert()
	return doc.as_dict()
