import frappe
from frappe.model.document import Document


class ZeusJourneyPlan(Document):
	def validate(self):
		self.total_planned_stops = len(self.stops)
