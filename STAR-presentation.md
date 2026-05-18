# STAR Presentation Guide
## Coquitlam College — IT Service Request Automation Platform

---

## Opening Line (say this first)

> "Coquitlam College had 4,000 students, 80 countries, and one IT inbox. We built the system that replaced it."

---

## S — Situation

Coquitlam College recently relocated its campus from Coquitlam to East Vancouver. The physical move happened. The IT support infrastructure did not modernize with it.

- 4,000+ students across three semesters
- 1,200+ international students from 80+ countries
- Three distinct academic programs: University Transfer, Senior Secondary, English Studies
- IT support model: one email inbox, one coordinator, one spreadsheet
- International students filing requests in broken English at 2am with no acknowledgement, no tracking, no SLA

When a ticket was lost, no one knew until the student showed up in person.

---

## T — Task

Design and deploy a serverless, event-driven IT service request platform on Microsoft Azure that:

1. Eliminates email as the intake mechanism
2. Automates triage, routing, and escalation
3. Provides full audit trail and searchable records
4. Notifies students automatically at every stage
5. Gives leadership real-time visibility into IT operations

Constraints: budget-sensitive private institution, no dedicated dev staff post-deployment, multi-user-type environment.

---

## A — Action (Five Phases)

### Phase 1 — Get Submitted
Built a structured web portal on Azure Static Web Apps. Students submit requests by category and urgency. Azure Functions HTTP trigger validates and ingests. Key Vault + Managed Identity secures every credential. Immediate acknowledgement to the student.

### Phase 2 — Get Routed
Azure Event Grid receives the validated event and routes by priority. Azure Service Bus handles async queue processing with dead-letter support for failed messages. A password reset and a server outage are no longer treated identically.

### Phase 3 — Get Stored
Every ticket written to Azure Cosmos DB — timestamped, searchable, auditable. File attachments routed to Azure Blob Storage. Full RBAC applied. For the first time, the IT coordinator can query by name, date, category, or status.

### Phase 4 — Get Notified
Azure Communication Services fires an automated confirmation email the moment the ticket is processed. Logic Apps monitors SLA windows — if a Priority 1 ticket goes unresolved, an escalation notification fires to the coordinator and department head automatically. Power Automate handles the routing workflow.

### Phase 5 — Get Monitored
Application Insights tracks function performance, error rates, and latency. Log Analytics Workspace aggregates all logs. Azure Monitor alert rules fire when thresholds are breached. The system watches itself — no manual log review required.

---

## R — Result

| Before | After |
|---|---|
| Email inbox | Structured web portal |
| Manual triage | Automated priority routing |
| Spreadsheet tracking | Cosmos DB with full audit trail |
| No notifications | Instant confirmation + SLA escalation |
| No visibility | Live dashboard with alert rules |
| One person's morning | 24/7 serverless automation |

The platform handles submission, classification, routing, notification, and escalation — serverless, scalable, and fully monitored. What used to live in a spreadsheet now runs on Azure.

---

## Anticipated Panel Questions

**Q: Why serverless over a traditional VM-based approach?**
A: Cost model. A private institution doesn't need a server running 24/7 for a workload that's bursty by nature. Serverless means we pay per execution, scale automatically during peak registration periods, and have zero infrastructure maintenance overhead.

**Q: Why Azure specifically?**
A: Coquitlam College's environment is Microsoft-native — M365, Outlook, Teams. Azure integrates natively with those systems. Logic Apps connects directly to Teams for escalation notifications. Azure AD/Entra ID manages identity. The ecosystem match is direct.

**Q: How does this handle the international student language barrier?**
A: The structured form eliminates free-text ambiguity. Students choose categories and urgency levels from dropdowns. They don't need to explain their problem in perfect English — they classify it. The AI categorization layer can extend this further in a future phase.

**Q: What happens if a function fails?**
A: Service Bus dead-letter queue captures failed messages — nothing is lost. Application Insights logs the failure. Azure Monitor fires an alert. The system has explicit failure handling at every async step.

**Q: How would this scale if Coquitlam College grew?**
A: Azure Functions scale horizontally on demand — automatically. Cosmos DB is globally distributed and serverless. There is no ceiling we'd hit at 4,000 students that wouldn't auto-resolve by Azure's infrastructure.

---

*Prepared for WIL Panel Presentation — Coquitlam College ITSM Platform*
