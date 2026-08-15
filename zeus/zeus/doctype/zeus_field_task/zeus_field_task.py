import frappe
from frappe.model.document import Document
from frappe.utils import now_datetime


class ZeusFieldTask(Document):
	def validate(self):
		if self.status == "Completed" and not self.completion_time:
			self.completion_time = now_datetime()
