import frappe


def execute():
	from zeus.install import ensure_roles

	ensure_roles()
