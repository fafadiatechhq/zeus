import frappe

ZEUS_ROLES = ("Zeus Field Staff", "Zeus Field Manager")


def after_install():
	ensure_roles()


def after_migrate():
	ensure_roles()


def ensure_roles():
	for role in ZEUS_ROLES:
		if not frappe.db.exists("Role", role):
			frappe.get_doc({"doctype": "Role", "role_name": role, "desk_access": 1}).insert(
				ignore_permissions=True
			)
