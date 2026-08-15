import frappe
from frappe.utils import cint, today

from zeus.api.utils import get_current_employee, haversine_distance, resolve_login_user


def _session_payload(employee=None):
	user = frappe.session.user
	if user in ("Guest",):
		frappe.throw(frappe._("Not logged in"), frappe.AuthenticationError)

	user_doc = frappe.get_cached_doc("User", user)
	employee = employee or get_current_employee(user)
	emp = frappe.get_cached_doc("Employee", employee)

	return {
		"user": user,
		"full_name": user_doc.full_name or emp.employee_name,
		"email": user_doc.email or emp.company_email or emp.personal_email,
		"phone": emp.cell_number or user_doc.mobile_no or user_doc.phone,
		"employee": emp.name,
		"employee_name": emp.employee_name,
		"employee_number": emp.employee_number,
		"designation": emp.designation,
		"department": emp.department,
		"company": emp.company,
		"image": emp.image or user_doc.user_image,
		"roles": frappe.get_roles(user),
	}


@frappe.whitelist(allow_guest=True)
def login(usr, pwd):
	"""Log in with User email/username or Employee ID / employee_number.

	Standard Frappe `POST /api/method/login` still works for email/username.
	Use this method when the client may send an Employee ID.
	"""
	if frappe.get_system_settings("disable_user_pass_login"):
		frappe.throw(frappe._("Username/password login is disabled for this site"))

	if frappe.session.user and frappe.session.user != "Guest":
		# Already authenticated — just return the session
		return {"full_name": frappe.session.data.get("full_name"), "session": _session_payload()}

	if not usr or not pwd:
		frappe.throw(frappe._("User and password are required"))

	user = resolve_login_user(usr)
	login_manager = frappe.auth.LoginManager()
	login_manager.authenticate(user=user, pwd=pwd)
	login_manager.post_login()

	return {
		"full_name": frappe.session.data.get("full_name") or getattr(login_manager, "full_name", None),
		"session": _session_payload(),
	}


@frappe.whitelist()
def get_session():
	"""Bootstrap payload for the mobile client: User + Employee profile."""
	return _session_payload()


@frappe.whitelist()
def get_dashboard():
	from zeus.api.attendance import get_monthly_summary, get_today_attendance
	from zeus.api.expense import count_pending_expenses

	employee = get_current_employee()
	date_today = today()

	open_tasks = frappe.get_list(
		"Zeus Field Task",
		filters={"assigned_to": employee, "status": ["in", ["Open", "In Progress"]]},
		fields=["name", "title", "status", "priority", "due_date", "site", "customer"],
		order_by="due_date asc",
	)

	completed_task_count = frappe.db.count(
		"Zeus Field Task",
		{"assigned_to": employee, "status": "Completed"},
	)

	journey_plan = None
	plan_name = frappe.db.get_value(
		"Zeus Journey Plan",
		{"employee": employee, "plan_date": date_today, "status": ["in", ["Draft", "Active"]]},
		"name",
		order_by="status desc",
	)
	if plan_name:
		journey_plan = frappe.get_doc("Zeus Journey Plan", plan_name).as_dict()

	visit_count = frappe.db.count(
		"Zeus Visit Log",
		{"employee": employee, "visit_datetime": [">=", date_today]},
	)

	pending_regularizations = frappe.db.count(
		"Zeus Attendance Regularization",
		{"employee": employee, "status": "Pending"},
	)

	attendance = get_today_attendance()
	month = get_monthly_summary()
	pending_expenses = count_pending_expenses(employee)

	return {
		"employee": employee,
		"date": date_today,
		"session": _session_payload(employee),
		"attendance": attendance,
		"open_tasks": open_tasks,
		"open_task_count": len(open_tasks),
		"completed_task_count": cint(completed_task_count),
		"journey_plan": journey_plan,
		"visit_count_today": visit_count,
		"pending_regularizations": pending_regularizations,
		"pending_expense_count": pending_expenses,
		"attendance_days_this_month": month.get("present", 0),
	}


@frappe.whitelist()
def geo_verify_site(site_name, latitude, longitude):
	if not frappe.db.exists("Zeus Site", site_name):
		frappe.throw(frappe._("Site {0} not found").format(site_name), frappe.DoesNotExistError)

	site = frappe.get_doc("Zeus Site", site_name)

	if not site.latitude or not site.longitude:
		frappe.throw(frappe._("Site {0} does not have coordinates configured").format(site_name))

	distance = haversine_distance(
		float(latitude),
		float(longitude),
		float(site.latitude),
		float(site.longitude),
	)

	radius = site.geofence_radius_meters or 0
	within_geofence = radius > 0 and distance <= radius

	return {
		"site": site_name,
		"distance_meters": round(distance, 2),
		"geofence_radius_meters": radius,
		"within_geofence": within_geofence,
	}
