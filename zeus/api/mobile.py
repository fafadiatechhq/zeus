import frappe
import math
from frappe.utils import today


def _get_current_employee():
	employee = frappe.db.get_value("Employee", {"user_id": frappe.session.user}, "name")
	if not employee:
		frappe.throw(frappe._("No employee record linked to the current user"))
	return employee


def _haversine_distance(lat1, lon1, lat2, lon2):
	"""Return distance in meters between two lat/lon points."""
	R = 6_371_000  # Earth radius in metres
	phi1, phi2 = math.radians(lat1), math.radians(lat2)
	dphi = math.radians(lat2 - lat1)
	dlambda = math.radians(lon2 - lon1)
	a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
	return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


@frappe.whitelist()
def get_dashboard():
	employee = _get_current_employee()
	date_today = today()

	# Today's open/in-progress tasks
	open_tasks = frappe.get_list(
		"Zeus Field Task",
		filters={"assigned_to": employee, "status": ["in", ["Open", "In Progress"]]},
		fields=["name", "title", "status", "priority", "due_date", "site", "customer"],
		order_by="due_date asc",
	)

	# Today's journey plan
	journey_plan = None
	plan_name = frappe.db.get_value(
		"Zeus Journey Plan",
		{"employee": employee, "plan_date": date_today, "status": ["in", ["Draft", "Active"]]},
		"name",
		order_by="status desc",
	)
	if plan_name:
		journey_plan = frappe.get_doc("Zeus Journey Plan", plan_name).as_dict()

	# Visit count today
	visit_count = frappe.db.count(
		"Zeus Visit Log",
		{"employee": employee, "visit_datetime": [">=", date_today]},
	)

	# Pending regularization requests
	pending_regularizations = frappe.db.count(
		"Zeus Attendance Regularization",
		{"employee": employee, "status": "Pending"},
	)

	return {
		"employee": employee,
		"date": date_today,
		"open_tasks": open_tasks,
		"open_task_count": len(open_tasks),
		"journey_plan": journey_plan,
		"visit_count_today": visit_count,
		"pending_regularizations": pending_regularizations,
	}


@frappe.whitelist()
def geo_verify_site(site_name, latitude, longitude):
	if not frappe.db.exists("Zeus Site", site_name):
		frappe.throw(frappe._("Site {0} not found").format(site_name), frappe.DoesNotExistError)

	site = frappe.get_doc("Zeus Site", site_name)

	if not site.latitude or not site.longitude:
		frappe.throw(frappe._("Site {0} does not have coordinates configured").format(site_name))

	distance = _haversine_distance(
		float(latitude), float(longitude),
		float(site.latitude), float(site.longitude),
	)

	radius = site.geofence_radius_meters or 0
	within_geofence = radius > 0 and distance <= radius

	return {
		"site": site_name,
		"distance_meters": round(distance, 2),
		"geofence_radius_meters": radius,
		"within_geofence": within_geofence,
	}
