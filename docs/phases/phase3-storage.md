# Phase 3 — Get Stored
## "Give every request an audit trail."

---

### Problem This Phase Solves

The old spreadsheet had no search. No timestamps. No attachment history. No way to prove when a ticket was received, who handled it, or what the resolution was. For a private institution serving international students, this is not just an operational problem — it is a compliance problem.

Phase 3 makes every ticket permanent, searchable, and auditable.

---

### What We Built

Every processed ticket is written to **Azure Cosmos DB** as a JSON document:

```json
{
  "id": "TKT-2024-00847",
  "studentId": "CC-20241234",
  "program": "University Transfer",
  "category": "Account Access",
  "urgency": "Priority 1",
  "description": "Cannot login to student portal before registration deadline",
  "status": "Open",
  "submittedAt": "2024-11-15T02:47:33Z",
  "slaDeadline": "2024-11-15T04:47:33Z",
  "attachmentUrl": "https://storage.../attachments/TKT-2024-00847/screenshot.png",
  "resolvedAt": null
}
```

File attachments route to **Azure Blob Storage** — organized by ticket ID, with SAS token access controlled through Key Vault.

All secrets — Cosmos DB connection string, Storage account key — accessed exclusively through **Managed Identity**. No credentials in code. No credentials in environment variables.

**RBAC** restricts access: the IT coordinator role can read all tickets; student-facing functions can only write their own.

---

### Services

| Service | Role |
|---|---|
| Azure Cosmos DB | Ticket records — NoSQL, serverless, globally distributed |
| Azure Blob Storage | File attachments organized by ticket ID |
| Azure Key Vault | All connection strings and storage keys |
| Managed Identity + RBAC | Credential-free access with least privilege |

---

### Why Cosmos DB Over Table Storage

The original ChatGPT plan suggested Azure Table Storage. We upgraded to Cosmos DB because:
- **Rich querying** — IT coordinator can filter by status, category, date range, student ID
- **Serverless billing** — pay per request unit, no provisioned throughput required at this scale
- **Schema flexibility** — ticket structure can evolve without migration scripts
- **SLA of 99.999%** — appropriate for a system students depend on for deadline-sensitive requests
