# Phase 2 — Get Routed
## "Give every request a brain."

---

### Problem This Phase Solves

In the old system, a student locked out of their account the night before final exam registration had the same priority as a student requesting a new keyboard. Both were emails in the same inbox, read in the same order, on the same morning.

Phase 2 makes the system understand the difference — automatically, before any human is involved.

---

### What We Built

When the HTTP trigger (Phase 1) publishes an event to **Azure Event Grid**, the routing layer takes over.

Event Grid evaluates the event payload — specifically the urgency field and category — and routes accordingly:

- **Priority 1 (Critical):** Directly triggers an escalation path in addition to queue processing
- **Priority 2 (High):** Standard queue with elevated retry policy
- **Priority 3 (Standard):** Normal processing queue

**Azure Service Bus** handles the queue. We chose Service Bus over Azure Storage Queue because:
- **Dead-letter queue** — failed messages are captured, not lost
- **Message lock duration** — prevents duplicate processing
- **Sessions** — enables FIFO ordering when needed by category
- **Enterprise-grade** — what production environments actually use

An **Azure Functions Queue Trigger** pulls messages from Service Bus and hands them to the processing layer (Phase 3).

---

### Services

| Service | Role |
|---|---|
| Azure Event Grid | Event routing and priority classification |
| Azure Service Bus | Async queue with dead-letter support |
| Azure Functions (Queue Trigger) | Backend request processor |

---

### Failure Handling

If a message fails processing three times, Service Bus automatically moves it to the **dead-letter queue**. Application Insights logs the failure. Azure Monitor fires an alert. No ticket is silently lost.
