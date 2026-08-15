import math

import frappe
from frappe.utils import cstr, getdate


ROLE_FIELD_STAFF = "Zeus Field Staff"
ROLE_FIELD_MANAGER = "Zeus Field Manager"
UNRESTRICTED_ROLES = {"System Manager", "HR Manager", "Administrator"}
MANAGER_ROLES = {ROLE_FIELD_MANAGER, "HR Manager", "System Manager", "Administrator"}


def get_current_employee(user=None):
	"""Return the Employee name linked to the session (or given) user.

	Throws if no active Employee is linked.
	"""
	user = user or frappe.session.user
	employee = frappe.db.get_value("Employee", {"user_id": user, "status": "Active"}, "name")
	if not employee:
		# Fall back without status filter so disabled employees get a clearer error
		employee = frappe.db.get_value("Employee", {"user_id": user}, "name")
		if employee:
			frappe.throw(frappe._("Employee record for {0} is not Active").format(user))
		frappe.throw(frappe._("No employee record linked to the current user"))
	return employee


def get_employee_or_none(user=None):
	user = user or frappe.session.user
	return frappe.db.get_value("Employee", {"user_id": user, "status": "Active"}, "name")


def get_user_roles(user=None):
	user = user or frappe.session.user
	return set(frappe.get_roles(user))


def is_unrestricted(user=None):
	return bool(get_user_roles(user) & UNRESTRICTED_ROLES)


def is_field_manager(user=None):
	return bool(get_user_roles(user) & MANAGER_ROLES)


def get_accessible_employees(user=None):
	"""Employees the user may see.

	Returns None when the user is unrestricted (System/HR Manager).
	"""
	user = user or frappe.session.user
	if is_unrestricted(user):
		return None

	employee = get_employee_or_none(user)
	if ROLE_FIELD_MANAGER in get_user_roles(user):
		if not employee:
			return []
		team = frappe.get_all("Employee", filters={"reports_to": employee}, pluck="name")
		return [employee, *team]

	if employee:
		return [employee]
	return []


def sql_in_clause(table, field, values):
	if not values:
		return "1=0"
	escaped = ", ".join(frappe.db.escape(v) for v in values)
	return f"`tab{table}`.`{field}` in ({escaped})"


def require_doctype(*doctypes):
	missing = [d for d in doctypes if not frappe.db.exists("DocType", d)]
	if missing:
		frappe.throw(
			frappe._("{0} is not available. Install ERPNext/HRMS.").format(", ".join(missing))
		)


def haversine_distance(lat1, lon1, lat2, lon2):
	"""Return distance in meters between two lat/lon points."""
	radius = 6_371_000
	phi1, phi2 = math.radians(lat1), math.radians(lat2)
	dphi = math.radians(lat2 - lat1)
	dlambda = math.radians(lon2 - lon1)
	a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
	return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def resolve_login_user(usr):
	"""Map email, username, Employee ID, or employee_number to a User name."""
	usr = cstr(usr).strip()
	if not usr:
		frappe.throw(frappe._("User is required"))

	if frappe.db.exists("User", usr):
		return usr

	by_username = frappe.db.get_value("User", {"username": usr}, "name")
	if by_username:
		return by_username

	employee = frappe.db.get_value(
		"Employee",
		{"name": usr},
		["name", "user_id", "status"],
		as_dict=True,
	)
	if not employee:
		employee = frappe.db.get_value(
			"Employee",
			{"employee_number": usr},
			["name", "user_id", "status"],
			as_dict=True,
		)

	if employee:
		if not employee.user_id:
			frappe.throw(
				frappe._("Employee {0} has no User account linked").format(employee.name)
			)
		if employee.status and employee.status != "Active":
			frappe.throw(frappe._("Employee {0} is not Active").format(employee.name))
		return employee.user_id

	frappe.throw(frappe._("Invalid login credentials"), frappe.AuthenticationError)


def month_bounds(year=None, month=None, reference=None):
	"""Return (from_date, to_date, year, month) for a calendar month."""
	from calendar import monthrange

	from frappe.utils import get_first_day, get_last_day, today

	if year and month:
		year, month = int(year), int(month)
		from_date = getdate(f"{year}-{month:02d}-01")
		to_date = getdate(f"{year}-{month:02d}-{monthrange(year, month)[1]}")
	else:
		ref = getdate(reference or today())
		from_date = get_first_day(ref)
		to_date = get_last_day(ref)
		year, month = from_date.year, from_date.month
	return from_date, to_date, year, month
