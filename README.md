# From Inbox to Automated
## Serverless Azure IT Service Request Platform — Coquitlam College

> *"Coquitlam College had 4,000 students, 80 countries, and one IT inbox. We built the system that replaced it."*

---

## The Situation

Coquitlam College didn't fail gradually. It relocated.

When the campus moved from Coquitlam to East Vancouver, everything physical moved with it — the classrooms, the staff, the students. But the IT support process stayed exactly where it was: an email inbox, a shared spreadsheet, and one IT coordinator reading through a backlog every morning.

The student body tells the real story. Over **4,000 students**. More than **80 countries** represented. Chinese, Indian, Korean, Filipino, and dozens of other international communities — many filing IT requests in their second or third language, at hours that made sense in their time zone, not Vancouver's.

A student in the English Studies program and a student in the University Transfer program had entirely different urgencies, entirely different systems they depended on, and entirely identical IT support experience: **send an email and wait.**

There was no tracking. No SLA. No triage. No escalation. No visibility.

If a ticket got lost — and they did — no one knew until a student showed up in person, frustrated, and already behind.

---

## The Task

Design and build a **serverless, event-driven IT service request platform** on Microsoft Azure.

**Constraints were real:**
- Budget-sensitive private institution — no dedicated IT development staff
- System had to run itself after deployment
- Three distinct user populations with different technical profiles and language needs
- Campus infrastructure already in flux from the relocation

**The mandate:** Replace reactive, human-dependent email support with scalable cloud-native automation — from submission to resolution.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Student Web Portal                          │
│              (Azure Static Web Apps — East Vancouver)           │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTP POST
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│            Azure Functions — HTTP Trigger                       │
│         (Input validation + Key Vault via Managed Identity)     │
└────────────────────────────┬────────────────────────────────────┘
                             │ Publishes Event
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Event Grid                             │
│              (Event routing and priority classification)        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Azure Service Bus Queue                        │
│        (Asynchronous processing + dead-letter queue)           │
└────────────────────────────┬────────────────────────────────────┘
                             │ Queue Trigger
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│           Azure Functions — Queue Processor                     │
├──────────────────┬──────────────────┬───────────────────────────┤
│   Cosmos DB      │  Blob Storage    │  Azure Communication Svc  │
│ (Request record) │ (Attachments)    │  (Email confirmation)     │
└──────────────────┴──────────────────┴───────────────┬───────────┘
                                                       │ P1 Escalation
                                                       ▼
                                        ┌──────────────────────────┐
                                        │  Azure Logic Apps        │
                                        │  (SLA breach escalation) │
                                        └──────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│        Azure Monitor + Application Insights + Log Analytics     │
│              (Live dashboard, SLA tracking, alerts)             │
└─────────────────────────────────────────────────────────────────┘
```

**Key Vault + Managed Identity** secures all secrets across every layer — no hardcoded credentials anywhere in the platform.

---

## The Five Phases

### Phase 1 — Get Submitted
*"Give students a portal, not an inbox."*

A multilingual-friendly web portal hosted on Azure Static Web Apps. Students submit structured requests — category, urgency, description, file attachment. An Azure Functions HTTP trigger validates input and acknowledges receipt immediately.

**The student in Shanghai at 2am finally knows their ticket exists.**

| Service | Role |
|---|---|
| Azure Static Web Apps | Frontend portal hosting |
| Azure Functions (HTTP Trigger) | Request intake and validation |
| Azure Key Vault | Secret management |
| Managed Identity | Credential-free access to Key Vault |

---

### Phase 2 — Get Routed
*"Give every request a brain."*

A password reset is not a server outage. Azure Event Grid and Azure Service Bus classify, prioritize, and route requests automatically — before any IT staff member opens their laptop. Priority 1 tickets trigger immediate escalation paths. Standard tickets enter the processing queue.

| Service | Role |
|---|---|
| Azure Event Grid | Event-driven routing layer |
| Azure Service Bus | Queue processing with dead-letter support |
| Azure Functions (Queue Trigger) | Backend request processor |

---

### Phase 3 — Get Stored
*"Give every request an audit trail."*

Every ticket lands in Azure Cosmos DB — searchable, timestamped, permanently on record. File attachments route to Azure Blob Storage. All secrets access only through Managed Identity.

For the first time, the IT coordinator can search by student name, by category, by date, by status. **Compliance is no longer a hope — it's a query.**

| Service | Role |
|---|---|
| Azure Cosmos DB | Ticket records (NoSQL, globally distributed) |
| Azure Blob Storage | File attachments |
| Azure Key Vault + RBAC | Secrets and access control |

---

### Phase 4 — Get Notified
*"Give people answers without anyone being asked."*

The moment a ticket is processed, Azure Communication Services fires an automated email confirmation — reference number, category, expected SLA. If a Priority 1 ticket goes unresolved past the SLA window, a Logic App triggers escalation to the IT coordinator and department head automatically.

**No one falls through the cracks. No student follows up into silence.**

| Service | Role |
|---|---|
| Azure Communication Services | Automated email confirmations |
| Azure Logic Apps | SLA breach escalation workflow |
| Power Automate | Priority routing and staff notification |

---

### Phase 5 — Get Monitored
*"Give leadership the dashboard they never had."*

Application Insights and a Log Analytics Workspace feed a live monitoring view — ticket volume, resolution times, error rates, SLA compliance. Azure Monitor fires alerts when the system itself encounters issues. The platform watches itself.

| Service | Role |
|---|---|
| Azure Monitor | Infrastructure-level alerting |
| Application Insights | Application performance and error tracking |
| Log Analytics Workspace | Centralized log aggregation and queries |
| Alert Rules | Automated notifications on threshold breach |

---

## Core Azure Services

| Service | Phase | Purpose |
|---|---|---|
| Azure Static Web Apps | 1 | Frontend portal |
| Azure Functions | 1, 2 | HTTP + Queue triggers |
| Azure Key Vault | 1, 3 | Secret management |
| Managed Identity | 1, 3 | Credential-free auth |
| Azure Event Grid | 2 | Event-driven routing |
| Azure Service Bus | 2 | Async queue + dead-letter |
| Azure Cosmos DB | 3 | Request storage |
| Azure Blob Storage | 3 | File attachments |
| Azure Communication Services | 4 | Email notifications |
| Azure Logic Apps | 4 | SLA escalation |
| Power Automate | 4 | Workflow automation |
| Azure Monitor | 5 | Infrastructure alerting |
| Application Insights | 5 | App performance tracking |
| Log Analytics Workspace | 5 | Log aggregation |

---

## Repository Structure

```
/coquitlam-itsm-azure
├── README.md                        ← This file (case study)
├── /docs
│   ├── architecture.md              ← Architecture narrative
│   ├── data-flow.md                 ← Service interaction map
│   ├── STAR-presentation.md         ← Panel presentation guide
│   └── /phases
│       ├── phase1-portal.md
│       ├── phase2-routing.md
│       ├── phase3-storage.md
│       ├── phase4-notifications.md
│       └── phase5-monitoring.md
├── /infra
│   └── main.bicep                   ← Infrastructure as Code
├── /frontend
│   └── index.html                   ← Static Web Apps portal
├── /functions
│   ├── /http-trigger                ← Request intake function
│   └── /queue-processor             ← Backend processing function
└── /diagrams
    └── topology.svg                 ← Architecture topology
```

---

## The Result

The platform replaces a reactive, human-dependent, email-based process with a serverless system that:

- **Accepts** requests 24/7 in a structured, trackable format
- **Routes** by priority automatically — zero human triage required
- **Stores** every record with full audit trail and file attachments
- **Notifies** students instantly and escalates overdue tickets without prompting
- **Monitors** itself and surfaces real-time data to leadership

For a private college serving 4,000 students across 80 countries — this is the difference between an inbox and an infrastructure.

---

## Technologies

![Azure](https://img.shields.io/badge/Microsoft_Azure-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Azure Functions](https://img.shields.io/badge/Azure_Functions-0062AD?style=flat&logo=azurefunctions&logoColor=white)
![Cosmos DB](https://img.shields.io/badge/Cosmos_DB-003366?style=flat&logo=microsoftazure&logoColor=white)
![Power Automate](https://img.shields.io/badge/Power_Automate-0066FF?style=flat&logo=microsoftpowerautomate&logoColor=white)

---

*WIL Project — Cloud-Native Serverless Architecture | Built on Microsoft Azure*
