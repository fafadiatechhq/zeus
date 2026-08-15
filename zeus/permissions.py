import frappe

from zeus.api.utils import (
	ROLE_FIELD_MANAGER,
	ROLE_FIELD_STAFF,
	get_accessible_employees,
	get_user_roles,
	is_unrestricted,
	sql_in_clause,
)


def _employee_clause(user, table, field):
	if is_unrestricted(user):
		return ""
	employees = get_accessible_employees(user)
	if employees is None:
		return ""
	return sql_in_clause(table, field, employees)


def _has_employee_access(doc, user, field="employee"):
	if is_unrestricted(user):
		return True
	employees = get_accessible_employees(user)
	if employees is None:
		return True
	return getattr(doc, field, None) in employees


def _skip_native_restriction(user):
	"""Do not interfere with HRMS/ERPNext for users who are not Zeus roles."""
	return not ({ROLE_FIELD_STAFF, ROLE_FIELD_MANAGER} & get_user_roles(user))


# ----- Zeus Field Task (assigned_to / assigned_by) -----

def get_field_task_query_conditions(user):
	if is_unrestricted(user):
		return ""
	employees = get_accessible_employees(user)
	if employees is None:
		return ""
	if not employees:
		return "1=0"
	assigned = sql_in_clause("Zeus Field Task", "assigned_to", employees)
	assigned_by = sql_in_clause("Zeus Field Task", "assigned_by", employees)
	return f"({assigned} or {assigned_by})"


def has_field_task_permission(doc, ptype=None, user=None, raise_exception=False):
	user = user or frappe.session.user
	if ptype == "create":
		return True
	if is_unrestricted(user):
		return True
	employees = get_accessible_employees(user)
	if employees is None:
		return True
	return doc.assigned_to in employees or doc.assigned_by in employees


# ----- employee-scoped Zeus DocTypes -----

def get_visit_log_query_conditions(user):
	return _employee_clause(user, "Zeus Visit Log", "employee")


def has_visit_log_permission(doc, ptype=None, user=None, raise_exception=False):
	user = user or frappe.session.user
	if ptype == "create":
		return True
	return _has_employee_access(doc, user)


def get_journey_plan_query_conditions(user):
	return _employee_clause(user, "Zeus Journey Plan", "employee")


def has_journey_plan_permission(doc, ptype=None, user=None, raise_exception=False):
	user = user or frappe.session.user
	if ptype == "create":
		return True
	return _has_employee_access(doc, user)


def get_regularization_query_conditions(user):
	return _employee_clause(user, "Zeus Attendance Regularization", "employee")


def has_regularization_permission(doc, ptype=None, user=None, raise_exception=False):
	user = user or frappe.session.user
	if ptype == "create":
		return True
	return _has_employee_access(doc, user)


# ----- Native ERPNext / HRMS DocTypes (only when caller has a Zeus role) -----

def get_employee_checkin_query_conditions(user):
	if _skip_native_restriction(user):
		return ""
	return _employee_clause(user, "Employee Checkin", "employee")


def has_employee_checkin_permission(doc, ptype=None, user=None, raise_exception=False):
	user = user or frappe.session.user
	if ptype == "create" or _skip_native_restriction(user):
		return True
	return _has_employee_access(doc, user)


def get_attendance_query_conditions(user):
	if _skip_native_restriction(user):
		return ""
	return _employee_clause(user, "Attendance", "employee")


def has_attendance_permission(doc, ptype=None, user=None, raise_exception=False):
	user = user or frappe.session.user
	if ptype == "create" or _skip_native_restriction(user):
		return True
	return _has_employee_access(doc, user)


def get_expense_claim_query_conditions(user):
	if _skip_native_restriction(user):
		return ""
	return _employee_clause(user, "Expense Claim", "employee")


def has_expense_claim_permission(doc, ptype=None, user=None, raise_exception=False):
	user = user or frappe.session.user
	if ptype == "create" or _skip_native_restriction(user):
		return True
	return _has_employee_access(doc, user)
