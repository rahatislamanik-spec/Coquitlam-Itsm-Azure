# Phase 1 — Get Submitted
## "Give students a portal, not an inbox."

---

### Problem This Phase Solves

An international student from China submits an IT request at 11pm Vancouver time. They write three sentences in broken English describing that they cannot access their student portal. The email arrives in a shared inbox. It sits there overnight. The next morning, the coordinator reads it, asks a clarifying question, and the student — now in their morning, which is Vancouver's evening — waits another cycle.

No acknowledgement. No reference number. No certainty the email was even received.

Phase 1 eliminates this completely.

---

### What We Built

A clean, structured web portal hosted on **Azure Static Web Apps**. Students select:
- **Request Category** (Account Access / Hardware / Software / Network / Other)
- **Urgency Level** (Priority 1 — Critical / Priority 2 — High / Priority 3 — Standard)
- **Program** (University Transfer / Senior Secondary / English Studies)
- **Description** (free text, limited to structured prompts)
- **File Attachment** (screenshot, error photo — routes to Blob Storage)

The moment they submit, an **Azure Functions HTTP trigger** validates the payload — checks required fields, sanitizes input, rejects malformed requests. If valid, the function publishes an event to Azure Event Grid and returns an immediate `202 Accepted` response with a reference number.

The student knows their ticket exists. Before Phase 1, they never did.

---

### Security Layer

All secrets — API keys, connection strings, storage account keys — live in **Azure Key Vault**. The Azure Function accesses Key Vault through **Managed Identity**, meaning zero credentials are stored in code or configuration files. No hardcoded secrets. No environment variable exposure.

---

### Services

| Service | Role |
|---|---|
| Azure Static Web Apps | Hosts the frontend portal (CDN-backed, globally distributed) |
| Azure Functions (HTTP Trigger) | Validates and ingests requests |
| Azure Key Vault | Stores all secrets and connection strings |
| Managed Identity | Grants the Function access to Key Vault without credentials |

---

### Key Design Decision

We chose **Azure Static Web Apps** over a traditional VM-hosted frontend because:
- Zero server maintenance
- Built-in CDN — fast for international students regardless of time zone
- Native integration with GitHub Actions for CI/CD deployment
- Free tier covers the college's traffic volume entirely
