# Phase 5 — Get Monitored
## "Give leadership the dashboard they never had."

---

### Problem This Phase Solves

The old system gave leadership nothing. No way to know how many IT tickets were open. No way to see which categories were most common. No way to measure whether the IT coordinator was overwhelmed or underutilized. No way to know whether the new platform itself was healthy.

Phase 5 makes everything visible — the platform, the tickets, the patterns, and the problems.

---

### What We Built

**Application Insights**
Every Azure Function is instrumented with Application Insights:
- Request success/failure rates
- Function execution duration (latency tracking)
- Dependency tracking (Cosmos DB calls, Service Bus interactions)
- Custom events: `TicketSubmitted`, `TicketProcessed`, `SLABreached`, `EscalationTriggered`

IT leadership can open Application Insights and see, in real time, how many tickets were submitted today, which category is trending, and whether any processing errors occurred.

**Log Analytics Workspace**
All logs — Function logs, Event Grid delivery logs, Service Bus activity, Logic App run history — aggregate into a single **Log Analytics Workspace**. KQL queries surface patterns:

```kql
// Tickets by category this week
customEvents
| where name == "TicketSubmitted"
| where timestamp > ago(7d)
| summarize count() by tostring(customDimensions.category)
| order by count_ desc
```

**Azure Monitor Alert Rules**
Automated alerts fire when:
- Function error rate exceeds 5% in a 15-minute window
- Service Bus dead-letter queue depth exceeds 10 messages
- SLA breach count exceeds 3 in one hour
- Any Function has zero executions for more than 2 hours (dead queue indicator)

Alerts route to the IT coordinator via email and Teams — integrated through the same Power Automate flow from Phase 4.

---

### Services

| Service | Role |
|---|---|
| Application Insights | Application performance, error tracking, custom events |
| Log Analytics Workspace | Centralized log aggregation and KQL queries |
| Azure Monitor | Infrastructure-level alert rules |
| Alert Rules | Threshold-based automated notifications |

---

### The Shift

| Before Phase 5 | After Phase 5 |
|---|---|
| No visibility into ticket volume | Real-time dashboard |
| No error detection | Automated alerts within minutes |
| No pattern recognition | Weekly trend reports via KQL |
| No SLA accountability | SLA breach logged, alerted, and escalated |
| Platform health unknown | Self-monitored with dead-queue detection |

The platform doesn't just process requests. It reports on itself.
