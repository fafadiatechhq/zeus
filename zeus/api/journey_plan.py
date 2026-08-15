import frappe
from frappe.utils import today, now_datetime


def _get_current_employee():
	employee = frappe.db.get_value("Employee", {"user_id": frappe.session.user}, "name")
	if not employee:
		frappe.throw(frappe._("No employee record linked to the current user"))
	return employee


@frappe.whitelist()
def get_journey_plans(employee=None, status=None, plan_date=None):
	filters = {}
	if employee:
		filters["employee"] = employee
	if status:
		filters["status"] = status
	if plan_date:
		filters["plan_date"] = plan_date

	plans = frappe.get_list(
		"Zeus Journey Plan",
		filters=filters,
		fields=["name", "employee", "plan_date", "status", "total_planned_stops"],
		order_by="plan_date desc",
	)
	return plans


@frappe.whitelist()
def get_my_plan_today():
	employee = _get_current_employee()

	plan_name = frappe.db.get_value(
		"Zeus Journey Plan",
		{"employee": employee, "plan_date": today(), "status": ["in", ["Draft", "Active"]]},
		"name",
		order_by="status desc",  # Active before Draft
	)

	if not plan_name:
		return None

	return get_journey_plan(plan_name)


@frappe.whitelist()
def get_journey_plan(plan_name):
	if not frappe.db.exists("Zeus Journey Plan", plan_name):
		frappe.throw(frappe._("Journey Plan {0} not found").format(plan_name), frappe.DoesNotExistError)

	return frappe.get_doc("Zeus Journey Plan", plan_name).as_dict()


@frappe.whitelist()
def create_journey_plan(plan_date, stops, employee=None):
	if not employee:
		employee = _get_current_employee()

	if isinstance(stops, str):
		import json
		stops = json.loads(stops)

	doc = frappe.get_doc({
		"doctype": "Zeus Journey Plan",
		"employee": employee,
		"plan_date": plan_date,
		"status": "Draft",
	})

	for stop in stops:
		doc.append("stops", {
			"sequence": stop.get("sequence"),
			"stop_type": stop.get("stop_type"),
			"linked_task": stop.get("linked_task"),
			"site": stop.get("site"),
			"customer": stop.get("customer"),
			"planned_time": stop.get("planned_time"),
		})

	doc.insert()
	return doc.as_dict()


@frappe.whitelist()
def activate_journey_plan(plan_name):
	if not frappe.db.exists("Zeus Journey Plan", plan_name):
		frappe.throw(frappe._("Journey Plan {0} not found").format(plan_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Zeus Journey Plan", plan_name)

	if doc.status != "Draft":
		frappe.throw(frappe._("Only Draft plans can be activated. Current status: {0}").format(doc.status))

	doc.status = "Active"
	doc.save()
	return doc.as_dict()


@frappe.whitelist()
def complete_stop(plan_name, stop_name, latitude=None, longitude=None, actual_time=None):
	if not frappe.db.exists("Zeus Journey Plan", plan_name):
		frappe.throw(frappe._("Journey Plan {0} not found").format(plan_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Zeus Journey Plan", plan_name)

	if doc.status != "Active":
		frappe.throw(frappe._("Stops can only be completed on an Active journey plan"))

	for stop in doc.stops:
		if stop.name == stop_name:
			stop.status = "Completed"
			stop.actual_time = actual_time or now_datetime()
			if latitude:
				stop.actual_latitude = float(latitude)
			if longitude:
				stop.actual_longitude = float(longitude)
			doc.save()

			# Auto-complete the plan if all stops are done or skipped
			if all(s.status in ("Completed", "Skipped") for s in doc.stops):
				doc.status = "Completed"
				doc.save()

			return doc.as_dict()

	frappe.throw(frappe._("Stop {0} not found in Journey Plan {1}").format(stop_name, plan_name))


@frappe.whitelist()
def skip_stop(plan_name, stop_name):
	if not frappe.db.exists("Zeus Journey Plan", plan_name):
		frappe.throw(frappe._("Journey Plan {0} not found").format(plan_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Zeus Journey Plan", plan_name)

	if doc.status != "Active":
		frappe.throw(frappe._("Stops can only be skipped on an Active journey plan"))

	for stop in doc.stops:
		if stop.name == stop_name:
			stop.status = "Skipped"
			doc.save()

			if all(s.status in ("Completed", "Skipped") for s in doc.stops):
				doc.status = "Completed"
				doc.save()

			return doc.as_dict()

	frappe.throw(frappe._("Stop {0} not found in Journey Plan {1}").format(stop_name, plan_name))
