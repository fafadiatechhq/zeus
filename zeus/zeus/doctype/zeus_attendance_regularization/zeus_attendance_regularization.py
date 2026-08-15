import frappe
from frappe.model.document import Document


class ZeusAttendanceRegularization(Document):
	def validate(self):
		if self.status in ("Approved", "Rejected") and not self.approver:
			frappe.throw(frappe._("Approver is required when approving or rejecting a regularization request"))

	def on_update(self):
		if self.status == "Approved":
			self._apply_regularization()

	def _apply_regularization(self):
		"""Create or update the Attendance record when a regularization is approved."""
		existing = frappe.db.get_value(
			"Attendance",
			{"employee": self.employee, "attendance_date": self.attendance_date},
			"name",
		)

		if existing:
			att = frappe.get_doc("Attendance", existing)
			if self.requested_check_in:
				att.in_time = self.requested_check_in
			if self.requested_check_out:
				att.out_time = self.requested_check_out
			att.save(ignore_permissions=True)
			self.db_set("linked_attendance", att.name)
		else:
			att = frappe.get_doc(
				{
					"doctype": "Attendance",
					"employee": self.employee,
					"attendance_date": self.attendance_date,
					"status": "Present",
					"in_time": self.requested_check_in,
					"out_time": self.requested_check_out,
				}
			)
			att.insert(ignore_permissions=True)
			self.db_set("linked_attendance", att.name)
