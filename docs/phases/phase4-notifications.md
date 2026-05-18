# Phase 4 — Get Notified
## "Give people answers without anyone being asked."

---

### Problem This Phase Solves

Under the old process, a student had no way of knowing whether their email was received, read, or acted on. Following up meant sending another email — which joined the same backlog. International students, already navigating language and timezone barriers, had no feedback loop at all.

Phase 4 closes every loop automatically.

---

### What We Built

**Student Confirmation (Immediate)**
The moment a ticket is written to Cosmos DB (Phase 3), **Azure Communication Services** fires an automated email to the student:

> Subject: IT Request Received — Reference #TKT-2024-00847
> Your request has been received and is being processed. Expected response: within 2 hours for Priority 1 requests.

No human action required. The student has a reference number and an SLA expectation before anyone on IT staff knows the ticket exists.

**SLA Escalation (Logic Apps)**
An **Azure Logic App** monitors Cosmos DB for tickets where `status = "Open"` and `slaDeadline < utcNow()`. When a Priority 1 ticket breaches its SLA window:

1. Logic App triggers
2. Escalation email fires to IT Coordinator and Department Head
3. Ticket status updates to `"Escalated"` in Cosmos DB
4. Application Insights logs the SLA breach event

**Priority Routing (Power Automate)**
A **Power Automate** flow handles internal staff notification — routing new Priority 1 and Priority 2 tickets to the coordinator's Teams channel in real time, without requiring them to monitor a dashboard.

---

### Services

| Service | Role |
|---|---|
| Azure Communication Services | Automated student email confirmations |
| Azure Logic Apps | SLA breach detection and escalation workflow |
| Power Automate | Internal staff notification via Teams |

---

### Why This Phase Matters for the Panel

Power Automate is a direct bridge between this platform and the Microsoft 365 environment Coquitlam College already uses. IT staff receive notifications in Teams — a tool they already have open. No new interface to monitor. The automation meets staff where they already work.
