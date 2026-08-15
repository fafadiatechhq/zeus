import frappe


@frappe.whitelist()
def get_sites(customer=None, is_active=1):
	filters = {"is_active": int(is_active)}
	if customer:
		filters["customer"] = customer

	sites = frappe.get_list(
		"Zeus Site",
		filters=filters,
		fields=["name", "site_name", "address", "latitude", "longitude", "geofence_radius_meters", "customer", "is_active"],
		order_by="site_name asc",
	)
	return sites


@frappe.whitelist()
def get_site(site_name):
	if not frappe.db.exists("Zeus Site", site_name):
		frappe.throw(frappe._("Site {0} not found").format(site_name), frappe.DoesNotExistError)

	return frappe.get_doc("Zeus Site", site_name).as_dict()


@frappe.whitelist()
def create_site(site_name, address=None, latitude=None, longitude=None,
				geofence_radius_meters=0, customer=None, is_active=1):
	doc = frappe.get_doc({
		"doctype": "Zeus Site",
		"site_name": site_name,
		"address": address,
		"latitude": latitude,
		"longitude": longitude,
		"geofence_radius_meters": geofence_radius_meters,
		"customer": customer,
		"is_active": int(is_active),
	})
	doc.insert()
	return doc.as_dict()


@frappe.whitelist()
def update_site(site_name, **kwargs):
	if not frappe.db.exists("Zeus Site", site_name):
		frappe.throw(frappe._("Site {0} not found").format(site_name), frappe.DoesNotExistError)

	allowed_fields = {"address", "latitude", "longitude", "geofence_radius_meters", "customer", "is_active"}
	doc = frappe.get_doc("Zeus Site", site_name)
	for field, value in kwargs.items():
		if field in allowed_fields:
			setattr(doc, field, value)
	doc.save()
	return doc.as_dict()
