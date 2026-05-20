# From Inbox to Automated
## Serverless Azure IT Service Request Platform — Coquitlam College

> *"Coquitlam College had 4,000 students, 80 countries, and one IT inbox. We built the system that replaced it."*

[![Azure](https://img.shields.io/badge/Microsoft_Azure-0078D4?style=flat&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com)
[![Azure Functions](https://img.shields.io/badge/Azure_Functions-0062AD?style=flat&logo=azurefunctions&logoColor=white)](https://azure.microsoft.com/en-us/products/functions)
[![Cosmos DB](https://img.shields.io/badge/Cosmos_DB-003366?style=flat&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/en-us/products/cosmos-db)
[![Power Automate](https://img.shields.io/badge/Power_Automate-0066FF?style=flat&logo=microsoftpowerautomate&logoColor=white)](https://powerautomate.microsoft.com)
[![Status](https://img.shields.io/badge/Status-Active_Build-brightgreen)](https://github.com/rahatislamanik-spec/Coquitlam-Itsm-Azure)

---

## 🏗️ Build Status

| Component | Status | Notes |
|---|---|---|
| Project narrative & documentation | ✅ Complete | Full case study live on GitHub Pages |
| Architecture diagram (interactive) | ✅ Complete | [View live →](https://rahatislamanik-spec.github.io/Coquitlam-Itsm-Azure/diagrams/architecture.html) |
| Student portal (`frontend/`) | ✅ Complete | HTML form — ready for Static Web Apps |
| HTTP trigger function | ✅ Complete | Validation, routing, CORS, App Insights |
| Queue processor function | ✅ Complete | Cosmos DB write, SLA deadline, audit trail |
| PowerShell deployment script | ✅ Complete | Key Vault + Managed Identity + all resources |
| Azure Communication Services (email) | 🔄 Phase 4 | In progress |
| Logic Apps SLA escalation | 🔄 Phase 4 | In progress |
| Power Automate Teams notification | 🔄 Phase 4 | In progress |
| Full Azure deployment & testing | 🔄 Phase 5 | Scheduled |

---

## The Situation

Coquitlam College didn't fail gradually. It relocated.

When the campus moved from Coquitlam to East Vancouver, everything physical moved with it — the classrooms, the staff, the students. But the IT support process stayed exactly where it was: an email inbox, a shared spreadsheet, and one IT coordinator reading through a backlog every morning.

The student body tells the real story. Over **4,000 students**. More than **80 countries** represented. Chinese, Indian, Korean, Filipino, and dozens of other international communities — many filing IT requests in their second or third language, at hours that made sense in their time zone, not Vancouver's.

A student in the English Studies program and a student in the University Transfer program had entirely different urgencies, entirely different systems they depended on, and entirely identical IT support experience: **send an email and wait.**

There was no tracking. No SLA. No triage. No escalation. No visibility.

If a ticket got lost — and they did — no one knew until a student showed up in person, frustrated, and already behind.

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

🔐 **Key Vault + Managed Identity** secures all secrets — zero hardcoded credentials.

👉 **[View Interactive Architecture Diagram →](https://rahatislamanik-spec.github.io/Coquitlam-Itsm-Azure/diagrams/architecture.html)**

---

## Repository Structure

```
/coquitlam-itsm-azure
├── README.md                            ← This file (case study)
├── frontend/
│   └── index.html                       ← Student portal — Azure Static Web Apps
├── functions/
│   ├── host.json                        ← Functions config (CORS, Service Bus, App Insights)
│   ├── package.json                     ← Node.js dependencies
│   ├── http-trigger/
│   │   ├── index.js                     ← Phase 1: Request intake + validation
│   │   └── function.json                ← HTTP binding (route: /api/submit-ticket)
│   └── queue-processor/
│       ├── index.js                     ← Phase 2→3: Cosmos DB write + audit trail
│       └── function.json                ← Service Bus trigger binding
├── infra/
│   └── deploy.ps1                       ← PowerShell: provisions all Azure resources
├── diagrams/
│   └── architecture.html               ← Interactive architecture diagram (GitHub Pages)
└── docs/
    ├── STAR-presentation.md             ← WIL panel presentation guide
    ├── architecture.md                  ← Architecture narrative
    └── phases/
        ├── phase1-portal.md
        ├── phase2-routing.md
        ├── phase3-storage.md
        ├── phase4-notifications.md
        └── phase5-monitoring.md
```

---

## The Five Phases

### Phase 1 — Get Submitted
*"Give students a portal, not an inbox."*

Azure Static Web Apps hosts the student portal. Structured form with category, urgency, program, and description. Azure Functions HTTP trigger validates, generates ticket ID, and routes to Service Bus.

| Service | Role |
|---|---|
| Azure Static Web Apps | Frontend portal — CDN-backed, globally distributed |
| Azure Functions (HTTP Trigger) | Request intake, validation, event publishing |
| Azure Key Vault | All secrets — connection strings, API keys |
| Managed Identity | Credential-free access to Key Vault |

---

### Phase 2 — Get Routed
*"Give every request a brain."*

Azure Event Grid and Service Bus classify and route automatically. P1/P2 tickets hit the priority queue. P3 goes to the standard queue. Dead-letter queue ensures zero silent failures.

| Service | Role |
|---|---|
| Azure Event Grid | Event-driven routing and priority classification |
| Azure Service Bus | Async queue with dead-letter support |
| Azure Functions (Queue Trigger) | Backend request processor |

---

### Phase 3 — Get Stored
*"Give every request an audit trail."*

Every ticket written to Cosmos DB — searchable, timestamped, auditable. SLA deadline calculated on write. Full audit array tracks every event in the ticket lifecycle.

| Service | Role |
|---|---|
| Azure Cosmos DB | Ticket records — serverless, globally distributed |
| Azure Blob Storage | File attachments organized by ticket ID |
| Key Vault + RBAC | Secrets and least-privilege access control |

---

### Phase 4 — Get Notified
*"Give people answers without anyone being asked."*

Azure Communication Services fires instant confirmation to the student. Logic Apps monitors for SLA breaches and escalates automatically. Power Automate delivers real-time Teams notifications to IT staff.

| Service | Role |
|---|---|
| Azure Communication Services | Automated student email confirmations |
| Azure Logic Apps | SLA breach detection and escalation |
| Power Automate | Teams notification for IT staff |

---

### Phase 5 — Get Monitored
*"Give leadership the dashboard they never had."*

Application Insights tracks every custom event. Log Analytics aggregates all logs for KQL querying. Azure Monitor fires alerts before any human notices a problem.

| Service | Role |
|---|---|
| Application Insights | App performance, error tracking, custom events |
| Log Analytics Workspace | Centralized log aggregation and KQL queries |
| Azure Monitor | Infrastructure-level alerting and alert rules |

---

## Deployment

### Prerequisites
- Azure CLI installed and authenticated (`az login`)
- PowerShell 7+
- Active Azure subscription

### Deploy all resources
```powershell
cd infra
.\deploy.ps1
```

The script provisions all 12 Azure resources, stores all secrets in Key Vault, and configures the Function App with Managed Identity — no credentials stored anywhere in code or app settings.

### Deploy functions
```bash
cd functions
npm install
func azure functionapp publish <your-function-app-name>
```

### Update frontend API URL
After deployment, update `FUNCTION_API_URL` in `frontend/index.html` with your Function App URL:
```javascript
const FUNCTION_API_URL = "https://<your-function-app>.azurewebsites.net/api/submit-ticket";
```

---

## Security Model

| Layer | Approach |
|---|---|
| Secrets | All stored in Azure Key Vault — zero plain text in code |
| Authentication | Managed Identity — Function App accesses Key Vault without credentials |
| Authorization | RBAC — least privilege on every resource |
| Transport | HTTPS enforced on all endpoints |
| Input | Server-side validation on every field before processing |

---

## The Result

The platform replaces a reactive, human-dependent, email-based process with a serverless system that:

- **Accepts** requests 24/7 in a structured, trackable format
- **Routes** by priority automatically — zero human triage required
- **Stores** every record with full audit trail and SLA deadline
- **Notifies** students instantly and escalates overdue tickets without prompting
- **Monitors** itself and surfaces real-time data to leadership

For a private college serving 4,000 students across 80 countries — this is the difference between an inbox and an infrastructure.

---

## Links

- 🌐 [Live Case Study (GitHub Pages)](https://rahatislamanik-spec.github.io/Coquitlam-Itsm-Azure/)
- 📊 [Interactive Architecture Diagram](https://rahatislamanik-spec.github.io/Coquitlam-Itsm-Azure/diagrams/architecture.html)
- 📋 [STAR Presentation Guide](docs/STAR-presentation.md)
- 👤 [GitHub Profile](https://github.com/rahatislamanik-spec)

---

*WIL Project 2026 · Cloud-Native Serverless Architecture · Built on Microsoft Azure*
