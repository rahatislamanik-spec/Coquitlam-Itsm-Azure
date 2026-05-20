# From Inbox to Automated
## Designing a Serverless Azure IT Service Request Platform — Coquitlam College

> *"Coquitlam College had 4,000 students, 80 countries, and one IT inbox. We're designing the cloud platform intended to modernize it."*

[![Azure](https://img.shields.io/badge/Microsoft_Azure-0078D4?style=flat&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com)
[![Azure Functions](https://img.shields.io/badge/Azure_Functions-0062AD?style=flat&logo=azurefunctions&logoColor=white)](https://azure.microsoft.com/en-us/products/functions)
[![Cosmos DB](https://img.shields.io/badge/Cosmos_DB-003366?style=flat&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/en-us/products/cosmos-db)
[![Power Automate](https://img.shields.io/badge/Power_Automate-0066FF?style=flat&logo=microsoftpowerautomate&logoColor=white)](https://powerautomate.microsoft.com)
[![Status](https://img.shields.io/badge/Status-Architecture_&_Development_Phase-orange)](https://github.com/rahatislamanik-spec/Coquitlam-Itsm-Azure)

---

> ⚠️ This project is currently in the early architecture, planning, and phased development stage as part of a 3+ month George Brown College WIL initiative.

---

## 🏗️ Build Status

| Component | Status | Notes |
|---|---|---|
| Project narrative & documentation | ✅ Complete | Initial case study and planning completed |
| Architecture diagram (interactive) | 🟡 In refinement | Initial architecture and workflow planning completed |
| Student portal (`frontend/`) | 🟡 Prototype phase | Early UI and intake workflow design |
| HTTP trigger function | 🟡 In development | Validation and routing logic being planned |
| Queue processor function | 🟡 In development | Cosmos DB write and audit logic planned |
| PowerShell deployment script | 🟡 Draft phase | Infrastructure scripting in progress |
| Azure Communication Services (email) | ⏳ Planned | Future implementation phase |
| Logic Apps SLA escalation | ⏳ Planned | Future implementation phase |
| Power Automate Teams notification | ⏳ Planned | Future implementation phase |
| Full Azure deployment & testing | ⏳ Not started | Scheduled for upcoming build phases |

---

## The Situation

As Coquitlam College transitioned operations from Coquitlam to East Vancouver, the IT support workflow remained heavily dependent on manual processes.

The student body tells the real story. Over **4,000 students**. More than **80 countries** represented. Chinese, Indian, Korean, Filipino, and dozens of other international communities — many filing IT requests in their second or third language, at hours that made sense in their time zone, not Vancouver's.

A student in the English Studies program and a student in the University Transfer program had entirely different urgencies, entirely different systems they depended on, and entirely identical IT support experience:

> **send an email and wait.**

There was:
- no structured intake
- no SLA tracking
- no escalation workflow
- no centralized visibility
- no automation
- no operational dashboard

As request volume increased, manual triage and inbox-based workflows became increasingly difficult to scale efficiently.

This project explores how modern Azure serverless architecture can help transform a reactive support workflow into an automated cloud-native operational system.

---

## Architecture Overview

```text
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

/coquitlam-itsm-azure
├── README.md
├── frontend/
│   └── index.html
├── functions/
│   ├── host.json
│   ├── package.json
│   ├── http-trigger/
│   │   ├── index.js
│   │   └── function.json
│   └── queue-processor/
│       ├── index.js
│       └── function.json
├── infra/
│   └── deploy.ps1
├── diagrams/
│   └── architecture.html
└── docs/
    ├── STAR-presentation.md
    ├── architecture.md
    └── phases/


Project Goal

Design a scalable cloud-native IT Service Request platform where students or employees can submit support requests through a web portal and Azure automatically processes, routes, stores, monitors, and escalates requests using serverless event-driven workflows.

The project is intended to simulate real-world enterprise IT operations and demonstrate practical cloud automation patterns used in modern organizations.

The Five Planned Phases
Phase 1 — Get Submitted

"Give students a portal, not an inbox."

Designing the student-facing request portal and serverless intake layer using Azure Static Web Apps and Azure Functions.

Service	Role
Azure Static Web Apps	Frontend portal
Azure Functions (HTTP Trigger)	Request intake and validation
Azure Key Vault	Secret management
Managed Identity	Credential-free authentication
Phase 2 — Get Routed

"Give every request a brain."

Designing event-driven routing and asynchronous queue processing workflows.

Service	Role
Azure Event Grid	Event-driven routing
Azure Service Bus	Queue-based processing
Azure Functions (Queue Trigger)	Backend request processing
Phase 3 — Get Stored

"Give every request an audit trail."

Designing scalable storage, ticket tracking, and audit logging workflows.

Service	Role
Azure Cosmos DB	Ticket storage and audit records
Azure Blob Storage	File attachments
Key Vault + RBAC	Secure access control
Phase 4 — Get Notified

"Give people answers without anyone being asked."

Planning notification and escalation workflows for students and IT staff.

Service	Role
Azure Communication Services	Email confirmations
Azure Logic Apps	SLA escalation workflows
Power Automate	Teams notifications
Phase 5 — Get Monitored

"Give leadership the dashboard they never had."

Planning operational dashboards, logging, monitoring, and observability workflows.

Service	Role
Application Insights	Application telemetry
Log Analytics Workspace	Centralized log aggregation
Azure Monitor	Alerting and monitoring
Key Engineering Decisions
Decision	Reason
Azure Service Bus instead of Storage Queue	Supports enterprise messaging patterns and dead-letter queues
Cosmos DB instead of traditional SQL	Flexible NoSQL schema and scalable serverless design
Managed Identity over hardcoded credentials	Eliminates credential exposure
Event-driven architecture	Supports scalable independent workflows
Azure Functions	Reduces infrastructure management overhead
Application Insights + Log Analytics	Centralized monitoring and observability
Security Model
Layer	Approach
Secrets	Azure Key Vault
Authentication	Managed Identity
Authorization	RBAC least-privilege model
Transport	HTTPS enforced
Input Validation	Server-side validation before processing
Expected Outcome

The completed platform is intended to replace a reactive, human-dependent, email-based process with a scalable serverless system capable of:

accepting requests 24/7 in a structured, trackable format
routing requests automatically based on priority
storing records with audit trails and SLA deadlines
notifying students and staff automatically
providing centralized monitoring and operational visibility

The project is currently focused on:

architecture planning
Azure service mapping
frontend prototyping
deployment scripting
phased implementation design

Implementation and live Azure deployment will continue over the next several months as part of the WIL build cycle.

Technologies

Node.js · Microsoft Azure · Azure Functions · Azure Service Bus · Azure Event Grid · Cosmos DB · Azure Monitor · Application Insights · PowerShell · GitHub Actions · Serverless Architecture

Links
👤 GitHub Profile
https://github.com/rahatislamanik-spec
💼 LinkedIn
https://www.linkedin.com/in/rahatislamanik/

WIL Project 2026 · Cloud-Native Serverless Architecture · Microsoft Azure · George Brown College
