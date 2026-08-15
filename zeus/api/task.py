import frappe
from frappe.utils import now_datetime

from zeus.api.utils import get_current_employee


@frappe.whitelist()
def get_tasks(assigned_to=None, status=None, priority=None, site=None, due_date=None):
	filters = {}
	if assigned_to:
		filters["assigned_to"] = assigned_to
	if status:
		filters["status"] = status
	if priority:
		filters["priority"] = priority
	if site:
		filters["site"] = site
	if due_date:
		filters["due_date"] = ["<=", due_date]

	tasks = frappe.get_list(
		"Zeus Field Task",
		filters=filters,
		fields=[
			"name", "title", "status", "priority", "due_date",
			"assigned_to", "assigned_by", "customer", "site",
			"requires_geo_verification", "completion_time",
		],
		order_by="due_date asc",
	)
	return tasks


@frappe.whitelist()
def get_my_tasks(status=None):
	employee = get_current_employee()
	filters = {"assigned_to": employee}
	if status:
		filters["status"] = status

	tasks = frappe.get_list(
		"Zeus Field Task",
		filters=filters,
		fields=[
			"name", "title", "status", "priority", "due_date",
			"customer", "site", "requires_geo_verification", "completion_time",
		],
		order_by="due_date asc",
	)
	return tasks


@frappe.whitelist()
def get_task(task_name):
	if not frappe.db.exists("Zeus Field Task", task_name):
		frappe.throw(frappe._("Task {0} not found").format(task_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Zeus Field Task", task_name)
	data = doc.as_dict()
	return data


@frappe.whitelist()
def create_task(title, due_date, assigned_to, status="Open", priority="Medium",
				assigned_by=None, customer=None, site=None, description=None,
				requires_geo_verification=0, checklist=None):
	doc = frappe.get_doc({
		"doctype": "Zeus Field Task",
		"title": title,
		"status": status,
		"priority": priority,
		"due_date": due_date,
		"assigned_to": assigned_to,
		"assigned_by": assigned_by,
		"customer": customer,
		"site": site,
		"description": description,
		"requires_geo_verification": int(requires_geo_verification),
	})

	if checklist:
		if isinstance(checklist, str):
			import json
			checklist = json.loads(checklist)
		for item in checklist:
			doc.append("checklist", {"label": item.get("label"), "is_done": item.get("is_done", 0)})

	doc.insert()
	return doc.as_dict()


@frappe.whitelist()
def update_task_status(task_name, status):
	valid_statuses = ("Open", "In Progress", "Completed", "Blocked")
	if status not in valid_statuses:
		frappe.throw(frappe._("Invalid status. Must be one of: {0}").format(", ".join(valid_statuses)))

	if not frappe.db.exists("Zeus Field Task", task_name):
		frappe.throw(frappe._("Task {0} not found").format(task_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Zeus Field Task", task_name)
	doc.status = status
	doc.save()
	return doc.as_dict()


@frappe.whitelist()
def complete_task(task_name, latitude=None, longitude=None, completion_notes=None, completion_photo=None):
	if not frappe.db.exists("Zeus Field Task", task_name):
		frappe.throw(frappe._("Task {0} not found").format(task_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Zeus Field Task", task_name)

	if doc.requires_geo_verification and (not latitude or not longitude):
		frappe.throw(frappe._("Latitude and longitude are required for geo-verified tasks"))

	doc.status = "Completed"
	doc.completion_time = now_datetime()
	if latitude:
		doc.completion_latitude = float(latitude)
	if longitude:
		doc.completion_longitude = float(longitude)
	if completion_notes:
		doc.completion_notes = completion_notes
	if completion_photo:
		doc.completion_photo = completion_photo

	doc.save()
	return doc.as_dict()


@frappe.whitelist()
def update_checklist_item(task_name, item_name, is_done):
	if not frappe.db.exists("Zeus Field Task", task_name):
		frappe.throw(frappe._("Task {0} not found").format(task_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Zeus Field Task", task_name)
	for item in doc.checklist:
		if item.name == item_name:
			item.is_done = int(is_done)
			doc.save()
			return doc.as_dict()

	frappe.throw(frappe._("Checklist item {0} not found in task {1}").format(item_name, task_name))
