/**
 * HTTP Trigger — Coquitlam College ITSM Platform
 * Phase 1: Get Submitted
 *
 * Receives IT service requests from the student portal.
 * Validates the payload, generates a ticket ID, and routes
 * to the appropriate Service Bus queue based on priority.
 *
 * Security: All secrets are injected via Key Vault references
 * in Azure App Settings — no credentials stored in code.
 *
 * Route: POST /api/submit-ticket
 */

const { ServiceBusClient } = require("@azure/service-bus");
const appInsights = require("applicationinsights");

// Initialise Application Insights if the connection string is available.
// APPINSIGHTS_INSTRUMENTATIONKEY is set automatically by Azure when App Insights is linked.
if (process.env.APPINSIGHTS_INSTRUMENTATIONKEY) {
  appInsights.setup().start();
}

module.exports = async function (context, req) {
  const client = appInsights.defaultClient;

  // ── CORS preflight ──────────────────────────────────────────────────
  // OPTIONS requests come from the browser before the actual POST.
  // Return the required CORS headers so the browser proceeds.
  if (req.method === "OPTIONS") {
    context.res = {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Max-Age": "86400"
      },
      body: ""
    };
    return;
  }

  context.log("HTTP trigger: ticket submission received.");

  try {
    const body = req.body || {};

    // ── Payload validation ──────────────────────────────────────────────
    const requiredFields = ["name", "email", "program", "category", "priority", "description"];
    const missingFields = requiredFields.filter((f) => !body[f] || String(body[f]).trim() === "");

    if (missingFields.length > 0) {
      context.res = {
        status: 400,
        headers: corsHeaders(),
        body: { message: "Missing required fields.", missingFields }
      };
      return;
    }

    // ── Build ticket ────────────────────────────────────────────────────
    const ticketId = generateTicketId();
    const priority = String(body.priority).toUpperCase();

    const ticket = {
      ticketId,
      status: "Received",
      name: body.name.trim(),
      email: body.email.trim().toLowerCase(),
      program: body.program.trim(),
      category: body.category,
      priority,
      description: body.description.trim(),
      submittedAt: body.submittedAt || new Date().toISOString(),
      source: "Azure Static Web Apps — Coquitlam College Portal"
    };

    // ── Route to Service Bus ────────────────────────────────────────────
    // Secrets are resolved from Key Vault at runtime via App Setting references.
    // The Function App's Managed Identity is granted Key Vault Secrets User role.
    const connectionString = process.env.SERVICE_BUS_CONNECTION_STRING;
    if (!connectionString) {
      throw new Error("SERVICE_BUS_CONNECTION_STRING is not configured. Check Key Vault reference in App Settings.");
    }

    const priorityQueueName  = process.env.PRIORITY_QUEUE_NAME  || "priority-queue";
    const standardQueueName  = process.env.STANDARD_QUEUE_NAME  || "standard-queue";
    const targetQueue = ["P1", "P2"].includes(priority) ? priorityQueueName : standardQueueName;

    const sbClient = new ServiceBusClient(connectionString);
    const sender   = sbClient.createSender(targetQueue);

    await sender.sendMessages({
      body: ticket,
      contentType: "application/json",
      subject: "TicketSubmitted",
      applicationProperties: {
        ticketId,
        priority,
        category: ticket.category
      }
    });

    await sender.close();
    await sbClient.close();

    // ── Track in App Insights ───────────────────────────────────────────
    if (client) {
      client.trackEvent({
        name: "TicketSubmitted",
        properties: { ticketId, priority, category: ticket.category, program: ticket.program }
      });
    }

    context.log(`Ticket ${ticketId} routed to ${targetQueue}.`);

    context.res = {
      status: 202,
      headers: corsHeaders(),
      body: {
        message: "Your IT request has been received and is being processed.",
        ticketId,
        queue: targetQueue,
        estimatedResponseTime: slaLabel(priority)
      }
    };

  } catch (error) {
    context.log.error("HTTP trigger error:", error.message);

    if (appInsights.defaultClient) {
      appInsights.defaultClient.trackException({ exception: error });
    }

    context.res = {
      status: 500,
      headers: corsHeaders(),
      body: { message: "Internal server error while submitting your ticket.", error: error.message }
    };
  }
};

// ── Helpers ─────────────────────────────────────────────────────────────

function generateTicketId() {
  const date   = new Date().toISOString().slice(0, 10).replace(/-/g, "");
  const random = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `ITSM-${date}-${random}`;
}

function corsHeaders() {
  return {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*"
  };
}

function slaLabel(priority) {
  const map = { P1: "within 4 hours", P2: "within 24 hours", P3: "within 72 hours" };
  return map[priority] || "within 72 hours";
}
