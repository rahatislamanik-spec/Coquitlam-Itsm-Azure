/**
 * Queue Processor — Coquitlam College ITSM Platform
 * Phase 2 → Phase 3: Get Routed → Get Stored
 *
 * Triggered by Azure Service Bus when a ticket enters the queue.
 * Writes the ticket record to Cosmos DB with full audit trail.
 * Logs custom telemetry events to Application Insights.
 *
 * Security: All secrets injected via Key Vault references.
 * The Function App's Managed Identity holds Cosmos DB Data Contributor role.
 *
 * Failure handling: If processing fails, Service Bus retries automatically.
 * After max retries, the message moves to the dead-letter queue.
 * Azure Monitor fires an alert when dead-letter depth exceeds threshold.
 */

const { CosmosClient } = require("@azure/cosmos");
const appInsights = require("applicationinsights");

if (process.env.APPINSIGHTS_INSTRUMENTATIONKEY) {
  appInsights.setup().start();
}

module.exports = async function (context, message) {
  const client = appInsights.defaultClient;
  context.log("Queue processor: ticket received from Service Bus.");

  try {
    // ── Parse ticket ──────────────────────────────────────────────────
    // Service Bus delivers the message body as parsed JSON.
    const ticket = message.body || message;

    if (!ticket || !ticket.ticketId) {
      throw new Error("Invalid message: missing ticketId. Message moved to dead-letter queue.");
    }

    context.log(`Processing ticket: ${ticket.ticketId} | Priority: ${ticket.priority}`);

    // ── Enrich ticket record ──────────────────────────────────────────
    const processedTicket = {
      ...ticket,
      id: ticket.ticketId,          // Cosmos DB requires 'id' field
      status: "Processed",
      processedAt: new Date().toISOString(),
      slaDeadline: calculateSlaDeadline(ticket.priority),
      audit: [
        {
          event: "TicketSubmitted",
          timestamp: ticket.submittedAt,
          actor: "Student Portal"
        },
        {
          event: "TicketProcessed",
          timestamp: new Date().toISOString(),
          actor: "Azure Functions Queue Processor"
        }
      ]
    };

    // ── Write to Cosmos DB ────────────────────────────────────────────
    // COSMOS_ENDPOINT and COSMOS_KEY are resolved from Key Vault at runtime.
    // Key Vault reference syntax in App Settings:
    //   @Microsoft.KeyVault(SecretUri=https://<vault>.vault.azure.net/secrets/CosmosKey/)
    const cosmosClient = new CosmosClient({
      endpoint: process.env.COSMOS_ENDPOINT,
      key: process.env.COSMOS_KEY
    });

    const database  = cosmosClient.database(process.env.COSMOS_DATABASE_NAME  || "itsm-db");
    const container = database.container(process.env.COSMOS_CONTAINER_NAME || "tickets");

    const { resource: created } = await container.items.create(processedTicket);
    context.log(`Ticket ${created.ticketId} written to Cosmos DB.`);

    // ── Track in App Insights ─────────────────────────────────────────
    if (client) {
      client.trackEvent({
        name: "TicketProcessed",
        properties: {
          ticketId:    ticket.ticketId,
          priority:    ticket.priority,
          category:    ticket.category,
          program:     ticket.program,
          slaDeadline: processedTicket.slaDeadline
        }
      });

      // Track SLA deadline as a metric for monitoring dashboards
      client.trackMetric({
        name: "TicketProcessed",
        value: 1,
        properties: { priority: ticket.priority }
      });
    }

    context.log(`Ticket ${ticket.ticketId} fully processed. SLA deadline: ${processedTicket.slaDeadline}`);

    // ── Next phases (to be wired in Phase 4) ─────────────────────────
    // TODO Phase 4a: Trigger Azure Communication Services email confirmation to student
    // TODO Phase 4b: Power Automate webhook for Teams notification on P1/P2
    // TODO Phase 4c: Logic Apps SLA breach monitor checks slaDeadline field

  } catch (error) {
    context.log.error(`Queue processor error for ticket: ${error.message}`);

    if (appInsights.defaultClient) {
      appInsights.defaultClient.trackException({
        exception: error,
        properties: { source: "queue-processor" }
      });
    }

    // Re-throw so Service Bus retries. After max retries,
    // message auto-moves to dead-letter queue.
    // Azure Monitor alert fires when dead-letter depth > 10.
    throw error;
  }
};

// ── Helpers ──────────────────────────────────────────────────────────────

function calculateSlaDeadline(priority) {
  const now = new Date();
  const hoursByPriority = { P1: 4, P2: 24, P3: 72 };
  const hours = hoursByPriority[String(priority).toUpperCase()] || 72;
  now.setHours(now.getHours() + hours);
  return now.toISOString();
}
