import frappe
from frappe.utils import add_days, flt, getdate, now_datetime, time_diff_in_hours, today

from zeus.api.utils import (
	get_current_employee,
	month_bounds,
	require_doctype,
)

DEVICE_ID = "Zeus Mobile App"


def _punch(log_type, latitude=None, longitude=None, site_name=None):
	require_doctype("Employee Checkin")
	employee = get_current_employee()
	date_today = today()
	today_logs = _today_checkins(employee, date_today)

	in_log = _first_log(today_logs, "IN")
	out_log = _last_log(today_logs, "OUT")

	if log_type == "IN":
		if in_log and not out_log:
			frappe.throw(frappe._("Already checked in at {0}").format(in_log.time))
		if in_log and out_log:
			frappe.throw(frappe._("Attendance for today is already complete"))
	elif log_type == "OUT":
		if not in_log:
			frappe.throw(frappe._("Cannot check out before checking in"))
		if out_log:
			frappe.throw(frappe._("Already checked out at {0}").format(out_log.time))

	if site_name:
		_enforce_geofence(site_name, latitude, longitude)

	if latitude is None or longitude is None:
		frappe.throw(frappe._("Latitude and longitude are required to {0}").format(
			"check in" if log_type == "IN" else "check out"
		))

	doc = frappe.get_doc(
		{
			"doctype": "Employee Checkin",
			"employee": employee,
			"log_type": log_type,
			"time": now_datetime(),
			"latitude": float(latitude),
			"longitude": float(longitude),
			"device_id": DEVICE_ID,
		}
	)
	doc.insert(ignore_permissions=True)
	return get_today_attendance()


def _enforce_geofence(site_name, latitude, longitude):
	from zeus.api.mobile import geo_verify_site

	if latitude is None or longitude is None:
		frappe.throw(frappe._("Latitude and longitude are required for geofenced check-in"))

	result = geo_verify_site(site_name, latitude, longitude)
	if result["geofence_radius_meters"] > 0 and not result["within_geofence"]:
		frappe.throw(
			frappe._(
				"You are {0}m away from {1} (allowed radius {2}m)"
			).format(result["distance_meters"], site_name, result["geofence_radius_meters"])
		)


def _today_checkins(employee, date_today):
	if not frappe.db.exists("DocType", "Employee Checkin"):
		return []
	return frappe.get_all(
		"Employee Checkin",
		filters=[
			["employee", "=", employee],
			["time", ">=", date_today],
			["time", "<", add_days(date_today, 1)],
		],
		fields=["name", "log_type", "time", "latitude", "longitude", "device_id"],
		order_by="time asc",
	)


def _first_log(logs, log_type):
	for log in logs:
		if log.log_type == log_type:
			return log
	return None


def _last_log(logs, log_type):
	match = None
	for log in logs:
		if log.log_type == log_type:
			match = log
	return match


def _serialize_checkin(log):
	if not log:
		return None
	return {
		"name": log.name,
		"time": log.time,
		"latitude": log.latitude,
		"longitude": log.longitude,
		"device_id": log.get("device_id") if isinstance(log, dict) else getattr(log, "device_id", None),
	}


def _attendance_status_from_records(attendance, in_log, out_log):
	if attendance:
		erp_status = (attendance.status or "").strip()
		if erp_status in ("On Leave",):
			return "on_leave"
		if erp_status in ("Absent",):
			return "absent"
		if out_log or erp_status in ("Present", "Work From Home", "Half Day"):
			if out_log or attendance.out_time:
				return "checked_out"
			if in_log or attendance.in_time:
				return "checked_in"
			return "present"

	if out_log:
		return "checked_out"
	if in_log:
		return "checked_in"
	return "not_checked_in"


def _map_history_status(erp_status):
	erp_status = (erp_status or "").strip()
	if erp_status in ("On Leave",):
		return "on_leave"
	if erp_status in ("Absent",):
		return "absent"
	if erp_status in ("Present", "Work From Home", "Half Day"):
		return "present"
	return (erp_status or "unknown").lower().replace(" ", "_")


def _get_today_attendance_doc(employee, date_today):
	if not frappe.db.exists("DocType", "Attendance"):
		return None
	name = frappe.db.get_value(
		"Attendance",
		{"employee": employee, "attendance_date": date_today, "docstatus": ["!=", 2]},
		"name",
	)
	if not name:
		return None
	return frappe.get_doc("Attendance", name)


@frappe.whitelist()
def checkin(latitude, longitude, site_name=None):
	"""Create an IN Employee Checkin for the session employee."""
	return _punch("IN", latitude, longitude, site_name)


@frappe.whitelist()
def checkout(latitude, longitude, site_name=None):
	"""Create an OUT Employee Checkin for the session employee."""
	return _punch("OUT", latitude, longitude, site_name)


@frappe.whitelist()
def get_today_attendance():
	"""Assemble today's punch state from Employee Checkin + Attendance."""
	employee = get_current_employee()
	date_today = today()
	logs = _today_checkins(employee, date_today)
	in_log = _first_log(logs, "IN")
	out_log = _last_log(logs, "OUT")
	attendance = _get_today_attendance_doc(employee, date_today)

	in_time = in_log.time if in_log else (attendance.in_time if attendance else None)
	out_time = out_log.time if out_log else (attendance.out_time if attendance else None)
	working_hours = None
	if in_time and out_time:
		working_hours = round(flt(time_diff_in_hours(out_time, in_time)), 2)
	elif attendance and attendance.get("working_hours"):
		working_hours = flt(attendance.working_hours)

	status = _attendance_status_from_records(attendance, in_log, out_log)

	return {
		"employee": employee,
		"date": date_today,
		"status": status,
		"check_in": _serialize_checkin(in_log) or (
			{"name": attendance.name, "time": attendance.in_time, "latitude": None, "longitude": None}
			if attendance and attendance.in_time and not in_log
			else None
		),
		"check_out": _serialize_checkin(out_log) or (
			{"name": attendance.name, "time": attendance.out_time, "latitude": None, "longitude": None}
			if attendance and attendance.out_time and not out_log
			else None
		),
		"working_hours": working_hours,
		"attendance": (
			{
				"name": attendance.name,
				"status": attendance.status,
				"in_time": attendance.in_time,
				"out_time": attendance.out_time,
			}
			if attendance
			else None
		),
	}


@frappe.whitelist()
def get_attendance_history(from_date=None, to_date=None, limit=31):
	"""Attendance history for the session employee (native Attendance DocType)."""
	employee = get_current_employee()
	if not from_date:
		from_date = add_days(today(), -30)
	if not to_date:
		to_date = today()

	records = []
	if frappe.db.exists("DocType", "Attendance"):
		rows = frappe.get_all(
			"Attendance",
			filters={
				"employee": employee,
				"attendance_date": ["between", [from_date, to_date]],
				"docstatus": ["!=", 2],
			},
			fields=["name", "attendance_date", "status", "in_time", "out_time", "working_hours"],
			order_by="attendance_date desc",
			limit=cint_limit(limit),
		)
		for row in rows:
			working_hours = row.working_hours
			if working_hours is None and row.in_time and row.out_time:
				working_hours = round(flt(time_diff_in_hours(row.out_time, row.in_time)), 2)
			records.append(
				{
					"name": row.name,
					"date": row.attendance_date,
					"status": _map_history_status(row.status),
					"erp_status": row.status,
					"check_in_time": row.in_time,
					"check_out_time": row.out_time,
					"working_hours": working_hours,
				}
			)

	# Include today from checkins if HR has not yet created an Attendance row
	date_today = getdate(today())
	if getdate(from_date) <= date_today <= getdate(to_date):
		if not any(getdate(r["date"]) == date_today for r in records):
			today_state = get_today_attendance()
			if today_state["status"] != "not_checked_in":
				records.insert(
					0,
					{
						"name": None,
						"date": date_today,
						"status": today_state["status"],
						"erp_status": None,
						"check_in_time": today_state["check_in"]["time"] if today_state["check_in"] else None,
						"check_out_time": today_state["check_out"]["time"] if today_state["check_out"] else None,
						"working_hours": today_state["working_hours"],
					},
				)

	return records


def cint_limit(limit):
	try:
		value = int(limit)
	except (TypeError, ValueError):
		value = 31
	return max(1, min(value, 366))


def _holiday_dates(employee, start, end):
	holiday_list = frappe.db.get_value("Employee", employee, "holiday_list")
	if not holiday_list:
		company = frappe.db.get_value("Employee", employee, "company")
		if company:
			holiday_list = frappe.db.get_value("Company", company, "default_holiday_list")
	if not holiday_list or not frappe.db.exists("DocType", "Holiday"):
		return set()
	dates = frappe.get_all(
		"Holiday",
		filters={"parent": holiday_list, "holiday_date": ["between", [start, end]]},
		pluck="holiday_date",
	)
	return {getdate(d) for d in dates}


def _working_days(employee, start, end):
	from datetime import timedelta

	holidays = _holiday_dates(employee, start, end)
	count = 0
	day = getdate(start)
	last = getdate(end)
	# Don't count future days
	today_date = getdate(today())
	if last > today_date:
		last = today_date
	while day <= last:
		if day not in holidays and day.weekday() < 5:
			count += 1
		day = day + timedelta(days=1)
	return count


@frappe.whitelist()
def get_monthly_summary(year=None, month=None):
	"""Present / Absent / Leave / Working Days for a calendar month."""
	employee = get_current_employee()
	from_date, to_date, year, month = month_bounds(year, month)

	present = absent = leave = 0
	if frappe.db.exists("DocType", "Attendance"):
		rows = frappe.get_all(
			"Attendance",
			filters={
				"employee": employee,
				"attendance_date": ["between", [from_date, to_date]],
				"docstatus": ["!=", 2],
			},
			fields=["status"],
		)
		for row in rows:
			mapped = _map_history_status(row.status)
			if mapped == "present":
				present += 1
			elif mapped == "absent":
				absent += 1
			elif mapped == "on_leave":
				leave += 1

	# Count today as present if checked in and no Attendance row yet
	today_date = getdate(today())
	if getdate(from_date) <= today_date <= getdate(to_date):
		today_state = get_today_attendance()
		if today_state["status"] in ("checked_in", "checked_out"):
			has_today = False
			if frappe.db.exists("DocType", "Attendance"):
				has_today = frappe.db.exists(
					"Attendance",
					{"employee": employee, "attendance_date": today(), "docstatus": ["!=", 2]},
				)
			if not has_today:
				present += 1

	working_days = _working_days(employee, from_date, to_date)

	return {
		"year": year,
		"month": month,
		"from_date": from_date,
		"to_date": to_date,
		"present": present,
		"absent": absent,
		"leave": leave,
		"working_days": working_days,
	}


@frappe.whitelist()
def get_regularizations(employee=None, status=None, from_date=None, to_date=None):
	filters = {}
	if employee:
		filters["employee"] = employee
	if status:
		filters["status"] = status
	if from_date and to_date:
		filters["attendance_date"] = ["between", [from_date, to_date]]
	elif from_date:
		filters["attendance_date"] = [">=", from_date]
	elif to_date:
		filters["attendance_date"] = ["<=", to_date]

	return frappe.get_list(
		"Zeus Attendance Regularization",
		filters=filters,
		fields=[
			"name", "employee", "attendance_date", "regularization_type",
			"status", "reason", "approver", "linked_attendance",
		],
		order_by="attendance_date desc",
	)


@frappe.whitelist()
def get_regularization(reg_name):
	if not frappe.db.exists("Zeus Attendance Regularization", reg_name):
		frappe.throw(frappe._("Regularization request {0} not found").format(reg_name), frappe.DoesNotExistError)

	return frappe.get_doc("Zeus Attendance Regularization", reg_name).as_dict()


@frappe.whitelist()
def create_regularization(attendance_date, regularization_type, reason,
						requested_check_in=None, requested_check_out=None, employee=None):
	if not employee:
		employee = get_current_employee()

	doc = frappe.get_doc({
		"doctype": "Zeus Attendance Regularization",
		"employee": employee,
		"attendance_date": attendance_date,
		"regularization_type": regularization_type,
		"reason": reason,
		"status": "Pending",
		"requested_check_in": requested_check_in,
		"requested_check_out": requested_check_out,
	})
	doc.insert()
	return doc.as_dict()


@frappe.whitelist()
def approve_regularization(reg_name, approver_remarks=None):
	if not frappe.db.exists("Zeus Attendance Regularization", reg_name):
		frappe.throw(frappe._("Regularization request {0} not found").format(reg_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Zeus Attendance Regularization", reg_name)

	if doc.status != "Pending":
		frappe.throw(frappe._("Only Pending requests can be approved. Current status: {0}").format(doc.status))

	doc.status = "Approved"
	doc.approver = get_current_employee()
	doc.approver_remarks = approver_remarks
	doc.save()
	return doc.as_dict()


@frappe.whitelist()
def reject_regularization(reg_name, approver_remarks=None):
	if not frappe.db.exists("Zeus Attendance Regularization", reg_name):
		frappe.throw(frappe._("Regularization request {0} not found").format(reg_name), frappe.DoesNotExistError)

	doc = frappe.get_doc("Zeus Attendance Regularization", reg_name)

	if doc.status != "Pending":
		frappe.throw(frappe._("Only Pending requests can be rejected. Current status: {0}").format(doc.status))

	doc.status = "Rejected"
	doc.approver = get_current_employee()
	doc.approver_remarks = approver_remarks
	doc.save()
	return doc.as_dict()
