"""
Zeus Demo Data Seeder
=====================
Seeds realistic demo data for Zeus development and integration testing.

Usage:
    bench --site <your-site> execute zeus.demo_data.seed

To remove all seeded data:
    bench --site <your-site> execute zeus.demo_data.teardown
"""

import frappe
from frappe.utils import add_days, today


# ---------------------------------------------------------------------------
# Data definitions
# ---------------------------------------------------------------------------

COMPANY = None  # resolved at runtime from default company

DEMO_PASSWORD = "zeus"

EMPLOYEES = [
    {
        "_id": "demo-mgr-priya",
        "first_name": "Priya",
        "last_name": "Patel",
        "designation": "Field Manager",
        "gender": "Female",
        "date_of_birth": "1988-04-12",
        "date_of_joining": "2022-01-10",
        "_role": "manager",
        "_email": "priya.patel@zeus.demo",
        "cell_number": "9876500001",
    },
    {
        "_id": "demo-field-ravi",
        "first_name": "Ravi",
        "last_name": "Sharma",
        "designation": "Field Sales Executive",
        "gender": "Male",
        "date_of_birth": "1995-07-23",
        "date_of_joining": "2023-03-15",
        "_role": "staff",
        "_email": "ravi.sharma@zeus.demo",
        "cell_number": "9876500002",
    },
    {
        "_id": "demo-field-ankit",
        "first_name": "Ankit",
        "last_name": "Mehta",
        "designation": "Service Technician",
        "gender": "Male",
        "date_of_birth": "1993-11-05",
        "date_of_joining": "2023-06-01",
        "_role": "staff",
        "_email": "ankit.mehta@zeus.demo",
        "cell_number": "9876500003",
    },
    {
        "_id": "demo-field-deepa",
        "first_name": "Deepa",
        "last_name": "Nair",
        "designation": "Delivery Executive",
        "gender": "Female",
        "date_of_birth": "1997-02-18",
        "date_of_joining": "2024-01-20",
        "_role": "staff",
        "_email": "deepa.nair@zeus.demo",
        "cell_number": "9876500004",
    },
]

CUSTOMERS = [
    {"customer_name": "Sunrise Industries Pvt Ltd", "customer_type": "Company", "customer_group": "Commercial"},
    {"customer_name": "Metro Electronics", "customer_type": "Company", "customer_group": "Commercial"},
    {"customer_name": "City Hospital", "customer_type": "Company", "customer_group": "Commercial"},
    {"customer_name": "Green Valley Farms", "customer_type": "Company", "customer_group": "Commercial"},
]

# Mumbai-area coordinates
SITES = [
    {
        "site_name": "Sunrise Industries - Main Gate",
        "address": "Plot 12, MIDC Industrial Area, Andheri East, Mumbai 400093",
        "latitude": 19.1136,
        "longitude": 72.8697,
        "geofence_radius_meters": 200,
        "_customer": "Sunrise Industries Pvt Ltd",
    },
    {
        "site_name": "Metro Electronics - Showroom",
        "address": "Shop 5, Linking Road, Bandra West, Mumbai 400050",
        "latitude": 19.0596,
        "longitude": 72.8295,
        "geofence_radius_meters": 150,
        "_customer": "Metro Electronics",
    },
    {
        "site_name": "City Hospital - Service Entrance",
        "address": "15, Hospital Road, Dadar, Mumbai 400014",
        "latitude": 19.0178,
        "longitude": 72.8478,
        "geofence_radius_meters": 100,
        "_customer": "City Hospital",
    },
    {
        "site_name": "Green Valley Farms - Warehouse",
        "address": "Survey No. 42, Vasai East, Palghar 401208",
        "latitude": 19.3728,
        "longitude": 72.8347,
        "geofence_radius_meters": 300,
        "_customer": "Green Valley Farms",
    },
    {
        "site_name": "Head Office",
        "address": "Level 4, Infinity Tower, BKC, Mumbai 400051",
        "latitude": 19.0639,
        "longitude": 72.8683,
        "geofence_radius_meters": 100,
        "_customer": None,
    },
]

# (employee _id, site_name, customer_name, purpose, notes, lat, lng, days_ago)
VISIT_LOGS = [
    (
        "demo-field-ravi",
        "Sunrise Industries - Main Gate",
        "Sunrise Industries Pvt Ltd",
        "Quarterly review meeting",
        "Discussed Q3 targets with purchase head. Follow-up needed on pending PO.",
        19.1137, 72.8698, 1,
    ),
    (
        "demo-field-ankit",
        "City Hospital - Service Entrance",
        "City Hospital",
        "AMC service visit",
        "Serviced UPS units on 2nd and 3rd floors. All units operational.",
        19.0179, 72.8479, 2,
    ),
    (
        "demo-field-deepa",
        "Metro Electronics - Showroom",
        "Metro Electronics",
        "Delivery of demo units",
        "Delivered 3 units as per delivery note DN-2026-089. Received signed POD.",
        19.0597, 72.8296, 0,
    ),
    (
        "demo-field-ravi",
        "Green Valley Farms - Warehouse",
        "Green Valley Farms",
        "New client introduction",
        "Met with Mr. Desai (Procurement). Shared product catalogue. High interest in bulk order.",
        19.3729, 72.8348, 3,
    ),
]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _ensure_master_data():
    """
    Bootstrap the ERPNext master data that the setup wizard normally creates.
    Safe to call multiple times — skips anything that already exists.
    Must be called once before seeding any ERPNext/HR/Zeus records.
    """
    _log("Ensuring ERPNext master data …")

    # ── Warehouse Types (required by Company.create_default_warehouses) ───────
    for wt in ("Receiving", "Sending", "Transit"):
        if not frappe.db.exists("Warehouse Type", wt):
            frappe.get_doc({"doctype": "Warehouse Type", "name": wt}).insert(ignore_permissions=True)

    # ── Currency ──────────────────────────────────────────────────────────────
    if not frappe.db.exists("Currency", "INR"):
        frappe.get_doc({
            "doctype": "Currency",
            "currency_name": "INR",
            "symbol": "₹",
            "enabled": 1,
        }).insert(ignore_permissions=True)

    # ── Country ───────────────────────────────────────────────────────────────
    if not frappe.db.exists("Country", "India"):
        frappe.get_doc({
            "doctype": "Country",
            "country_name": "India",
            "code": "in",
            "date_format": "dd-mm-yyyy",
        }).insert(ignore_permissions=True)

    # ── Gender ────────────────────────────────────────────────────────────────
    for g in ("Male", "Female", "Other", "Prefer not to say"):
        if not frappe.db.exists("Gender", g):
            frappe.get_doc({"doctype": "Gender", "gender": g}).insert(ignore_permissions=True)

    # ── Designations used by demo employees ───────────────────────────────────
    for d in ("Field Manager", "Field Sales Executive", "Service Technician", "Delivery Executive"):
        if not frappe.db.exists("Designation", d):
            frappe.get_doc({"doctype": "Designation", "designation_name": d}).insert(ignore_permissions=True)

    # ── Customer Group ────────────────────────────────────────────────────────
    if not frappe.db.exists("Customer Group", "All Customer Groups"):
        frappe.get_doc({
            "doctype": "Customer Group",
            "customer_group_name": "All Customer Groups",
            "is_group": 1,
        }).insert(ignore_permissions=True)
    if not frappe.db.exists("Customer Group", "Commercial"):
        frappe.get_doc({
            "doctype": "Customer Group",
            "customer_group_name": "Commercial",
            "parent_customer_group": "All Customer Groups",
        }).insert(ignore_permissions=True)

    # ── Territory ─────────────────────────────────────────────────────────────
    if not frappe.db.exists("Territory", "All Territories"):
        frappe.get_doc({
            "doctype": "Territory",
            "territory_name": "All Territories",
            "is_group": 1,
        }).insert(ignore_permissions=True)

    frappe.db.commit()
    _log("Master data ready.")


def _get_company():
    global COMPANY
    if not COMPANY:
        COMPANY = frappe.db.get_single_value("Global Defaults", "default_company")
        if not COMPANY:
            COMPANY = frappe.db.get_value("Company", {}, "name")
        if not COMPANY:
            _log("No company found — creating demo company …")
            doc = frappe.get_doc({
                "doctype": "Company",
                "company_name": "Zeus Demo Co",
                "abbr": "ZDC",
                "default_currency": "INR",
                "country": "India",
            })
            doc.insert(ignore_permissions=True)
            frappe.db.set_single_value("Global Defaults", "default_company", doc.name)
            frappe.db.commit()
            COMPANY = doc.name
            _log(f"Created demo company: {COMPANY}")
    return COMPANY


def _employee_full_name(emp_def):
    return f"{emp_def['first_name']} {emp_def['last_name']}"


def _get_employee_name(emp_id):
    """Return the ERPNext Employee.name (autoname) for a demo employee id stored in employee_number."""
    return frappe.db.get_value("Employee", {"employee_number": emp_id}, "name")


def _demo_email(emp_def):
    return emp_def.get("_email") or (
        f"{emp_def['first_name'].lower()}.{emp_def['last_name'].lower()}@zeus.demo"
    )


def _log(msg):
    print(f"  [zeus-seed] {msg}")


# ---------------------------------------------------------------------------
# Creators
# ---------------------------------------------------------------------------

def _ensure_employee_user(emp, emp_name):
    """Create a User for the demo employee and link Employee.user_id.

    Idempotent: existing users keep their password; missing roles and the
    Employee link are still applied.
    """
    from zeus.api.utils import ROLE_FIELD_MANAGER, ROLE_FIELD_STAFF

    email = _demo_email(emp)
    zeus_role = ROLE_FIELD_MANAGER if emp["_role"] == "manager" else ROLE_FIELD_STAFF

    if not frappe.db.exists("User", email):
        user = frappe.get_doc(
            {
                "doctype": "User",
                "email": email,
                "first_name": emp["first_name"],
                "last_name": emp["last_name"],
                "enabled": 1,
                "send_welcome_email": 0,
                "user_type": "System User",
                "new_password": DEMO_PASSWORD,
            }
        )
        user.flags.ignore_password_policy = True
        user.flags.no_welcome_mail = True
        user.insert(ignore_permissions=True)
        user.add_roles("Employee", zeus_role)
        _log(f"  created User {email}")
    else:
        user = frappe.get_doc("User", email)
        existing = {d.role for d in user.roles}
        changed = False
        for role in ("Employee", zeus_role):
            if role not in existing:
                user.append("roles", {"role": role})
                changed = True
        if changed:
            user.save(ignore_permissions=True)
        _log(f"  skip User {email} (already exists)")

    values = {"user_id": email, "company_email": email}
    if emp.get("cell_number") and frappe.get_meta("Employee").has_field("cell_number"):
        values["cell_number"] = emp["cell_number"]
    frappe.db.set_value("Employee", emp_name, values)


def _seed_employees():
    _log("Creating demo employees …")
    company = _get_company()
    for emp in EMPLOYEES:
        emp_name = _get_employee_name(emp["_id"])
        if emp_name:
            _log(f"  skip {_employee_full_name(emp)} (already exists)")
        else:
            doc = frappe.get_doc(
                {
                    "doctype": "Employee",
                    "first_name": emp["first_name"],
                    "last_name": emp["last_name"],
                    "employee_number": emp["_id"],
                    "designation": emp.get("designation"),
                    "gender": emp["gender"],
                    "date_of_birth": emp.get("date_of_birth"),
                    "date_of_joining": emp["date_of_joining"],
                    "company": company,
                    "status": "Active",
                    "cell_number": emp.get("cell_number"),
                    "company_email": _demo_email(emp),
                }
            )
            doc.insert(ignore_permissions=True)
            emp_name = doc.name
            _log(f"  created {_employee_full_name(emp)} → {emp_name}")

        _ensure_employee_user(emp, emp_name)

    # Set reports_to for field staff once all employees exist
    mgr_name = _get_employee_name("demo-mgr-priya")
    if mgr_name:
        for emp in EMPLOYEES:
            if emp["_role"] == "staff":
                emp_name = _get_employee_name(emp["_id"])
                if emp_name:
                    frappe.db.set_value("Employee", emp_name, "reports_to", mgr_name)


def _seed_customers():
    _log("Creating demo customers …")
    territory = frappe.db.get_value("Territory", {"is_group": 0}, "name") or "All Territories"
    for cust in CUSTOMERS:
        if frappe.db.exists("Customer", cust["customer_name"]):
            _log(f"  skip {cust['customer_name']} (already exists)")
            continue
        doc = frappe.get_doc(
            {
                "doctype": "Customer",
                "customer_name": cust["customer_name"],
                "customer_type": cust.get("customer_type", "Company"),
                "customer_group": cust.get("customer_group", "Commercial"),
                "territory": territory,
            }
        )
        doc.insert(ignore_permissions=True)
        _log(f"  created {doc.name}")


def _seed_sites():
    _log("Creating Zeus Sites …")
    for s in SITES:
        if frappe.db.exists("Zeus Site", s["site_name"]):
            _log(f"  skip {s['site_name']} (already exists)")
            continue
        customer_name = s.get("_customer")
        doc = frappe.get_doc(
            {
                "doctype": "Zeus Site",
                "site_name": s["site_name"],
                "address": s.get("address"),
                "latitude": s["latitude"],
                "longitude": s["longitude"],
                "geofence_radius_meters": s.get("geofence_radius_meters", 0),
                "customer": customer_name if frappe.db.exists("Customer", customer_name) else None,
                "is_active": 1,
            }
        )
        doc.insert(ignore_permissions=True)
        _log(f"  created {doc.name}")


def _seed_field_tasks():
    _log("Creating Zeus Field Tasks …")
    ravi = _get_employee_name("demo-field-ravi")
    ankit = _get_employee_name("demo-field-ankit")
    deepa = _get_employee_name("demo-field-deepa")
    mgr = _get_employee_name("demo-mgr-priya")

    tasks = [
        # Completed task — Ravi visited Sunrise
        {
            "title": "Quarterly review meeting — Sunrise Industries",
            "assigned_to": ravi,
            "assigned_by": mgr,
            "due_date": add_days(today(), -1) + " 17:00:00",
            "priority": "High",
            "status": "Completed",
            "customer": "Sunrise Industries Pvt Ltd",
            "site": "Sunrise Industries - Main Gate",
            "requires_geo_verification": 1,
            "completion_notes": "Meeting done. Shared Q3 proposal. Follow-up call scheduled for Friday.",
            "completion_time": add_days(today(), -1) + " 14:30:00",
            "completion_latitude": 19.1137,
            "completion_longitude": 72.8698,
            "checklist": [
                {"label": "Share Q3 proposal document", "is_done": 1},
                {"label": "Collect signed NDA", "is_done": 1},
                {"label": "Confirm next meeting date", "is_done": 1},
            ],
        },
        # In Progress — Ankit doing service visit
        {
            "title": "AMC service visit — City Hospital UPS units",
            "assigned_to": ankit,
            "assigned_by": mgr,
            "due_date": today() + " 18:00:00",
            "priority": "High",
            "status": "In Progress",
            "customer": "City Hospital",
            "site": "City Hospital - Service Entrance",
            "requires_geo_verification": 1,
            "checklist": [
                {"label": "Check UPS units on 2nd floor", "is_done": 1},
                {"label": "Check UPS units on 3rd floor", "is_done": 1},
                {"label": "Update service log in system", "is_done": 0},
                {"label": "Collect service completion sign-off", "is_done": 0},
            ],
        },
        # Open — Deepa delivery tomorrow
        {
            "title": "Deliver demo units to Metro Electronics",
            "assigned_to": deepa,
            "assigned_by": mgr,
            "due_date": add_days(today(), 1) + " 12:00:00",
            "priority": "Medium",
            "status": "Open",
            "customer": "Metro Electronics",
            "site": "Metro Electronics - Showroom",
            "requires_geo_verification": 0,
            "checklist": [
                {"label": "Verify units before loading", "is_done": 0},
                {"label": "Collect delivery receipt (POD)", "is_done": 0},
            ],
        },
        # Open — Ravi new client visit
        {
            "title": "New client introduction — Green Valley Farms",
            "assigned_to": ravi,
            "assigned_by": mgr,
            "due_date": add_days(today(), 2) + " 11:00:00",
            "priority": "Medium",
            "status": "Open",
            "customer": "Green Valley Farms",
            "site": "Green Valley Farms - Warehouse",
            "requires_geo_verification": 1,
            "checklist": [
                {"label": "Present product catalogue", "is_done": 0},
                {"label": "Understand current vendor list", "is_done": 0},
                {"label": "Collect contact details of decision maker", "is_done": 0},
            ],
        },
        # Blocked — Ankit waiting for parts
        {
            "title": "Install replacement inverter — Sunrise Industries",
            "assigned_to": ankit,
            "assigned_by": mgr,
            "due_date": add_days(today(), 3) + " 14:00:00",
            "priority": "Urgent",
            "status": "Blocked",
            "customer": "Sunrise Industries Pvt Ltd",
            "site": "Sunrise Industries - Main Gate",
            "requires_geo_verification": 1,
            "completion_notes": "Blocked — replacement inverter part not yet received from warehouse.",
            "checklist": [
                {"label": "Remove faulty unit", "is_done": 0},
                {"label": "Install replacement unit", "is_done": 0},
                {"label": "Run load test", "is_done": 0},
            ],
        },
        # Open — Deepa next week
        {
            "title": "Weekly stock check — Metro Electronics",
            "assigned_to": deepa,
            "assigned_by": mgr,
            "due_date": add_days(today(), 5) + " 10:00:00",
            "priority": "Low",
            "status": "Open",
            "customer": "Metro Electronics",
            "site": "Metro Electronics - Showroom",
            "requires_geo_verification": 0,
        },
    ]

    for t in tasks:
        if frappe.db.exists("Zeus Field Task", {"title": t["title"], "assigned_to": t["assigned_to"]}):
            _log(f"  skip '{t['title']}' (already exists)")
            continue
        checklist = t.pop("checklist", [])
        doc = frappe.get_doc({"doctype": "Zeus Field Task", **t})
        for item in checklist:
            doc.append("checklist", item)
        doc.insert(ignore_permissions=True)
        _log(f"  created {doc.name} [{t['status']}] → {t['title'][:50]}")


def _seed_employee_checkins():
    _log("Creating Employee Checkins (today) …")
    # Mumbai HO coordinates with slight variance per employee
    checkins = [
        ("demo-mgr-priya",  "IN",  today() + " 09:02:00", 19.0640, 72.8684),
        ("demo-field-ravi", "IN",  today() + " 08:47:00", 19.0641, 72.8682),
        ("demo-field-ravi", "OUT", today() + " 09:10:00", 19.1137, 72.8698),  # left for site
        ("demo-field-ankit","IN",  today() + " 09:15:00", 19.0178, 72.8479),  # checked in at hospital
        ("demo-field-deepa","IN",  today() + " 08:55:00", 19.0640, 72.8683),
    ]
    for emp_id, log_type, time, lat, lng in checkins:
        emp_name = _get_employee_name(emp_id)
        if not emp_name:
            continue
        if frappe.db.exists("Employee Checkin", {"employee": emp_name, "time": time}):
            _log(f"  skip checkin {emp_id} {log_type} {time}")
            continue
        doc = frappe.get_doc(
            {
                "doctype": "Employee Checkin",
                "employee": emp_name,
                "log_type": log_type,
                "time": time,
                "latitude": lat,
                "longitude": lng,
                "device_id": "Zeus Mobile App",
            }
        )
        doc.insert(ignore_permissions=True)
        _log(f"  created checkin {emp_id} {log_type} @ {time}")


def _seed_attendance_regularizations():
    _log("Creating Zeus Attendance Regularizations …")
    ravi = _get_employee_name("demo-field-ravi")
    deepa = _get_employee_name("demo-field-deepa")
    mgr = _get_employee_name("demo-mgr-priya")

    regs = [
        {
            "employee": ravi,
            "attendance_date": add_days(today(), -3),
            "regularization_type": "Missed Punch",
            "reason": "Forgot to check out after the client visit. Was in a meeting till late.",
            "requested_check_in": add_days(today(), -3) + " 09:05:00",
            "requested_check_out": add_days(today(), -3) + " 19:30:00",
            "status": "Approved",
            "approver": mgr,
            "approver_remarks": "Verified with client visit log. Approved.",
        },
        {
            "employee": deepa,
            "attendance_date": add_days(today(), -1),
            "regularization_type": "Wrong Location",
            "reason": "Was at the delivery site (Metro Electronics, Bandra) but app showed incorrect location.",
            "requested_check_in": add_days(today(), -1) + " 08:50:00",
            "requested_check_out": add_days(today(), -1) + " 17:45:00",
            "status": "Pending",
            "approver": mgr,
        },
    ]

    for r in regs:
        if frappe.db.exists(
            "Zeus Attendance Regularization",
            {"employee": r["employee"], "attendance_date": r["attendance_date"]},
        ):
            _log(f"  skip regularization for {r['employee']} on {r['attendance_date']}")
            continue
        doc = frappe.get_doc({"doctype": "Zeus Attendance Regularization", **r})
        doc.insert(ignore_permissions=True)
        _log(f"  created regularization {doc.name} [{r['status']}]")


def _seed_visit_logs():
    _log("Creating Zeus Visit Logs …")
    for vl in VISIT_LOGS:
        emp_id, site, customer, purpose, notes, lat, lng, days_ago = vl
        emp_name = _get_employee_name(emp_id)
        if not emp_name:
            continue
        visit_dt = add_days(today(), -days_ago) + " 11:30:00"
        if frappe.db.exists("Zeus Visit Log", {"employee": emp_name, "visit_datetime": visit_dt}):
            _log(f"  skip visit log {emp_id} @ {visit_dt}")
            continue
        doc = frappe.get_doc(
            {
                "doctype": "Zeus Visit Log",
                "employee": emp_name,
                "visit_datetime": visit_dt,
                "customer": customer if frappe.db.exists("Customer", customer) else None,
                "site": site if frappe.db.exists("Zeus Site", site) else None,
                "purpose": purpose,
                "notes": notes,
                "latitude": lat,
                "longitude": lng,
            }
        )
        doc.insert(ignore_permissions=True)
        _log(f"  created {doc.name} — {purpose[:50]}")


def _seed_journey_plans():
    _log("Creating Zeus Journey Plans …")
    ravi = _get_employee_name("demo-field-ravi")
    ankit = _get_employee_name("demo-field-ankit")

    plans = [
        {
            "employee": ravi,
            "plan_date": add_days(today(), 1),
            "status": "Draft",
            "stops": [
                {
                    "sequence": 1,
                    "stop_type": "Customer",
                    "customer": "Metro Electronics",
                    "planned_time": add_days(today(), 1) + " 10:00:00",
                    "status": "Pending",
                },
                {
                    "sequence": 2,
                    "stop_type": "Task",
                    "site": "Green Valley Farms - Warehouse",
                    "planned_time": add_days(today(), 1) + " 12:30:00",
                    "status": "Pending",
                },
                {
                    "sequence": 3,
                    "stop_type": "Customer",
                    "customer": "Sunrise Industries Pvt Ltd",
                    "planned_time": add_days(today(), 1) + " 15:00:00",
                    "status": "Pending",
                },
            ],
        },
        {
            "employee": ankit,
            "plan_date": today(),
            "status": "Active",
            "stops": [
                {
                    "sequence": 1,
                    "stop_type": "Task",
                    "site": "City Hospital - Service Entrance",
                    "planned_time": today() + " 09:30:00",
                    "actual_time": today() + " 09:42:00",
                    "actual_latitude": 19.0179,
                    "actual_longitude": 72.8479,
                    "status": "Completed",
                },
                {
                    "sequence": 2,
                    "stop_type": "Site",
                    "site": "Sunrise Industries - Main Gate",
                    "planned_time": today() + " 14:00:00",
                    "status": "Pending",
                },
            ],
        },
    ]

    for p in plans:
        if frappe.db.exists("Zeus Journey Plan", {"employee": p["employee"], "plan_date": p["plan_date"]}):
            _log(f"  skip journey plan for {p['employee']} on {p['plan_date']}")
            continue
        stops = p.pop("stops")
        doc = frappe.get_doc({"doctype": "Zeus Journey Plan", **p})
        for stop in stops:
            doc.append("stops", stop)
        doc.insert(ignore_permissions=True)
        _log(f"  created {doc.name} [{p['status']}] — {len(stops)} stops")


def _seed_expense_claims():
    _log("Creating demo Expense Claims …")
    ravi = _get_employee_name("demo-field-ravi")
    ankit = _get_employee_name("demo-field-ankit")
    company = _get_company()

    # Find a payable account and expense account for the company
    expense_account = frappe.db.get_value(
        "Account",
        {"account_type": "Expense Account", "company": company, "is_group": 0},
        "name",
    )
    if not expense_account:
        _log("  skip expense claims — no expense account found")
        return

    claims = [
        {
            "employee": ravi,
            "posting_date": add_days(today(), -1),
            "company": company,
            "expense_details": [
                {"expense_date": add_days(today(), -1), "description": "Cab to Sunrise Industries client visit", "amount": 420, "expense_account": expense_account},
                {"expense_date": add_days(today(), -1), "description": "Lunch with client", "amount": 650, "expense_account": expense_account},
            ],
        },
        {
            "employee": ankit,
            "posting_date": today(),
            "company": company,
            "expense_details": [
                {"expense_date": today(), "description": "Auto rickshaw to City Hospital", "amount": 180, "expense_account": expense_account},
                {"expense_date": today(), "description": "Spare parts — cable ties and thermal paste", "amount": 340, "expense_account": expense_account},
            ],
        },
    ]

    for c in claims:
        if frappe.db.exists(
            "Expense Claim",
            {"employee": c["employee"], "posting_date": c["posting_date"], "company": company},
        ):
            _log(f"  skip expense claim for {c['employee']} on {c['posting_date']}")
            continue
        expenses = c.pop("expense_details")
        doc = frappe.get_doc({"doctype": "Expense Claim", **c})
        for exp in expenses:
            doc.append("expenses", exp)
        doc.insert(ignore_permissions=True)
        _log(f"  created {doc.name} — {len(expenses)} line(s)")


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def seed():
    """Seed all Zeus demo data. Safe to run multiple times (idempotent)."""
    print("\n=== Zeus Demo Data Seeder ===\n")

    # bench execute sets frappe.flags.in_migrate = True which causes
    # setup_module_map(include_all_apps=False) — only frappe's own modules are
    # registered, so Zeus and ERPNext/HRMS doctypes fall back to frappe.core.
    # Explicitly register every module we'll touch.
    _register_modules = {
        "zeus": "zeus",
        # ERPNext modules
        "accounts": "erpnext", "buying": "erpnext", "selling": "erpnext",
        "stock": "erpnext", "setup": "erpnext", "crm": "erpnext",
        "hr": "hrms",
        "payroll": "hrms",
    }
    for module, app in _register_modules.items():
        if module not in frappe.local.module_app:
            frappe.local.module_app[module] = app

    frappe.db.begin()
    try:
        _ensure_master_data()
        _seed_employees()
        _seed_customers()
        _seed_sites()
        _seed_field_tasks()
        _seed_visit_logs()
        _seed_journey_plans()
        # Attendance / expense seeders — skip gracefully on unexpected errors.
        try:
            _seed_employee_checkins()
        except Exception as e:
            _log(f"  skip employee checkins — {e}")
        try:
            _seed_attendance_regularizations()
        except Exception as e:
            _log(f"  skip attendance regularizations — {e}")
        try:
            _seed_expense_claims()
        except Exception as e:
            _log(f"  skip expense claims — {e}")
        frappe.db.commit()
        print("\n✓ Zeus demo data seeded successfully.\n")
    except Exception:
        frappe.db.rollback()
        raise


def teardown():
    """Remove all Zeus demo data created by this seeder."""
    print("\n=== Zeus Demo Data Teardown ===\n")
    frappe.db.begin()
    try:
        # Zeus-specific DocTypes — delete all seeded records
        for doctype in [
            "Zeus Journey Plan",
            "Zeus Visit Log",
            "Zeus Attendance Regularization",
            "Zeus Field Task",
            "Zeus Site",
        ]:
            names = frappe.get_all(doctype, pluck="name")
            for name in names:
                frappe.delete_doc(doctype, name, ignore_permissions=True, force=True)
            if names:
                print(f"  deleted {len(names)} {doctype} record(s)")

        # Employee Checkins seeded by Zeus (identified by device_id)
        checkin_names = frappe.get_all(
            "Employee Checkin", {"device_id": "Zeus Mobile App"}, pluck="name"
        )
        for name in checkin_names:
            frappe.delete_doc("Employee Checkin", name, ignore_permissions=True, force=True)
        if checkin_names:
            print(f"  deleted {len(checkin_names)} Employee Checkin record(s)")

        # Demo employees (identified by employee_number prefix)
        emp_ids = [e["_id"] for e in EMPLOYEES]
        emp_names = frappe.get_all(
            "Employee", {"employee_number": ["in", emp_ids]}, pluck="name"
        )
        for name in emp_names:
            frappe.db.set_value("Employee", name, "user_id", None)
            frappe.delete_doc("Employee", name, ignore_permissions=True, force=True)
        if emp_names:
            print(f"  deleted {len(emp_names)} Employee record(s)")

        for emp in EMPLOYEES:
            email = _demo_email(emp)
            if frappe.db.exists("User", email):
                frappe.delete_doc("User", email, ignore_permissions=True, force=True)
                print(f"  deleted User {email}")

        # Demo customers
        cust_names = [c["customer_name"] for c in CUSTOMERS]
        for name in cust_names:
            if frappe.db.exists("Customer", name):
                frappe.delete_doc("Customer", name, ignore_permissions=True, force=True)
                print(f"  deleted Customer {name}")

        frappe.db.commit()
        print("\n✓ Zeus demo data removed.\n")
    except Exception:
        frappe.db.rollback()
        raise
