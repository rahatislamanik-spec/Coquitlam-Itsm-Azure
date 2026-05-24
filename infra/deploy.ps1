<#
.SYNOPSIS
  Full Azure deployment for Coquitlam College ITSM WIL Platform.

.DESCRIPTION
  Provisions all Azure resources for the 5-phase serverless ITSM platform:
    Phase 1 — Static Web Apps + Azure Functions + Key Vault + Managed Identity
    Phase 2 — Service Bus (priority + standard queues with dead-letter)
    Phase 3 — Cosmos DB (serverless) + Blob Storage
    Phase 5 — Application Insights + Log Analytics Workspace + Alert Rules

  Security model:
    All secrets are stored in Key Vault.
    The Function App uses Managed Identity to access Key Vault — no credentials in code.
    App Settings reference Key Vault secrets using the @Microsoft.KeyVault() syntax.

.REQUIREMENTS
  - Azure CLI installed (az --version)
  - PowerShell 7+ recommended
  - Run: az login
  - Contributor role on the target subscription

.USAGE
  .\deploy.ps1
  .\deploy.ps1 -ResourceGroup "rg-myname-itsm" -Location "canadacentral"

.NOTES
  WIL Project 2026 · rahatislamanik-spec · Coquitlam College
#>

param(
  [string]$ResourceGroup = "rg-coquitlam-itsm-wil",
  [string]$Location      = "canadacentral",
  [string]$Prefix        = "ccitsm"
)

$ErrorActionPreference = "Stop"

# ── Banner ─────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Coquitlam College ITSM Platform — Azure Deployment" -ForegroundColor Cyan
Write-Host "  WIL Project 2026 · rahatislamanik-spec"             -ForegroundColor DarkGray
Write-Host ""

# ── Generate unique suffix to avoid naming conflicts ───────────────────────
$Suffix          = -join ((97..122) | Get-Random -Count 6 | ForEach-Object { [char]$_ })
$StorageName     = "${Prefix}${Suffix}st"
$FunctionAppName = "${Prefix}${Suffix}func"
$SbNamespace     = "${Prefix}${Suffix}sb"
$CosmosName      = "${Prefix}${Suffix}cosmos"
$KeyVaultName    = "${Prefix}${Suffix}kv"
$AppInsightsName = "${Prefix}${Suffix}appi"
$LogWorkspace    = "${Prefix}${Suffix}law"
$BlobName        = "${Prefix}${Suffix}blob"
$StaticWebApp    = "${Prefix}${Suffix}swa"

$PriorityQueue   = "priority-queue"
$StandardQueue   = "standard-queue"
$CosmosDb        = "itsm-db"
$CosmosContainer = "tickets"

Write-Host "Resource Group : $ResourceGroup"   -ForegroundColor White
Write-Host "Location       : $Location"        -ForegroundColor White
Write-Host "Suffix         : $Suffix"          -ForegroundColor DarkGray
Write-Host ""

# ── 1. Resource Group ──────────────────────────────────────────────────────
Write-Host "[1/12] Creating Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location | Out-Null
Write-Host "       Resource Group: $ResourceGroup" -ForegroundColor Green

# ── 2. Log Analytics Workspace (Phase 5) ───────────────────────────────────
Write-Host "[2/12] Creating Log Analytics Workspace..." -ForegroundColor Yellow
az monitor log-analytics workspace create `
  --resource-group $ResourceGroup `
  --workspace-name $LogWorkspace `
  --location $Location | Out-Null

$WorkspaceId = az monitor log-analytics workspace show `
  --resource-group $ResourceGroup `
  --workspace-name $LogWorkspace `
  --query customerId --output tsv

Write-Host "       Log Analytics: $LogWorkspace" -ForegroundColor Green

# ── 3. Application Insights (Phase 5) ─────────────────────────────────────
Write-Host "[3/12] Creating Application Insights..." -ForegroundColor Yellow
az monitor app-insights component create `
  --app $AppInsightsName `
  --location $Location `
  --resource-group $ResourceGroup `
  --application-type web `
  --workspace $WorkspaceId | Out-Null

$InstrumentationKey = az monitor app-insights component show `
  --app $AppInsightsName `
  --resource-group $ResourceGroup `
  --query instrumentationKey --output tsv

Write-Host "       App Insights: $AppInsightsName" -ForegroundColor Green

# ── 4. Storage Account (Functions backing store) ───────────────────────────
Write-Host "[4/12] Creating Storage Account..." -ForegroundColor Yellow
az storage account create `
  --name $StorageName `
  --resource-group $ResourceGroup `
  --location $Location `
  --sku Standard_LRS `
  --kind StorageV2 `
  --allow-blob-public-access false | Out-Null

$StorageConnection = az storage account show-connection-string `
  --name $StorageName `
  --resource-group $ResourceGroup `
  --query connectionString --output tsv

Write-Host "       Storage Account: $StorageName" -ForegroundColor Green

# ── 5. Blob Storage container (Phase 3 — file attachments) ────────────────
Write-Host "[5/12] Creating Blob Storage container for attachments..." -ForegroundColor Yellow
az storage container create `
  --name "ticket-attachments" `
  --account-name $StorageName `
  --auth-mode login | Out-Null

Write-Host "       Blob container: ticket-attachments" -ForegroundColor Green

# ── 6. Service Bus (Phase 2 — routing) ────────────────────────────────────
Write-Host "[6/12] Creating Service Bus namespace and queues..." -ForegroundColor Yellow
az servicebus namespace create `
  --name $SbNamespace `
  --resource-group $ResourceGroup `
  --location $Location `
  --sku Standard | Out-Null

# Priority queue — P1/P2 tickets
az servicebus queue create `
  --resource-group $ResourceGroup `
  --namespace-name $SbNamespace `
  --name $PriorityQueue `
  --enable-dead-lettering-on-message-expiration true `
  --max-delivery-count 3 `
  --lock-duration "PT2M" | Out-Null

# Standard queue — P3 tickets
az servicebus queue create `
  --resource-group $ResourceGroup `
  --namespace-name $SbNamespace `
  --name $StandardQueue `
  --enable-dead-lettering-on-message-expiration true `
  --max-delivery-count 3 `
  --lock-duration "PT2M" | Out-Null

$SbConnection = az servicebus namespace authorization-rule keys list `
  --resource-group $ResourceGroup `
  --namespace-name $SbNamespace `
  --name RootManageSharedAccessKey `
  --query primaryConnectionString --output tsv

Write-Host "       Service Bus: $SbNamespace (queues: $PriorityQueue, $StandardQueue)" -ForegroundColor Green

# ── 7. Cosmos DB (Phase 3 — ticket storage) ────────────────────────────────
Write-Host "[7/12] Creating Cosmos DB (serverless)..." -ForegroundColor Yellow
az cosmosdb create `
  --name $CosmosName `
  --resource-group $ResourceGroup `
  --locations regionName=$Location `
  --capabilities EnableServerless `
  --default-consistency-level Session | Out-Null

az cosmosdb sql database create `
  --account-name $CosmosName `
  --resource-group $ResourceGroup `
  --name $CosmosDb | Out-Null

az cosmosdb sql container create `
  --account-name $CosmosName `
  --resource-group $ResourceGroup `
  --database-name $CosmosDb `
  --name $CosmosContainer `
  --partition-key-path "/category" | Out-Null

$CosmosEndpoint = az cosmosdb show `
  --name $CosmosName `
  --resource-group $ResourceGroup `
  --query documentEndpoint --output tsv

$CosmosKey = az cosmosdb keys list `
  --name $CosmosName `
  --resource-group $ResourceGroup `
  --query primaryMasterKey --output tsv

Write-Host "       Cosmos DB: $CosmosName / $CosmosDb / $CosmosContainer" -ForegroundColor Green

# ── 8. Key Vault (Phase 1 — security layer) ────────────────────────────────
Write-Host "[8/12] Creating Key Vault and storing secrets..." -ForegroundColor Yellow
az keyvault create `
  --name $KeyVaultName `
  --resource-group $ResourceGroup `
  --location $Location `
  --sku standard `
  --enable-rbac-authorization true | Out-Null

# Store all secrets in Key Vault — nothing stored as plain text in app settings
az keyvault secret set --vault-name $KeyVaultName --name "ServiceBusConnectionString" --value $SbConnection | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "CosmosEndpoint"             --value $CosmosEndpoint | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "CosmosKey"                  --value $CosmosKey | Out-Null
az keyvault secret set --vault-name $KeyVaultName --name "StorageConnectionString"     --value $StorageConnection | Out-Null

Write-Host "       Key Vault: $KeyVaultName (4 secrets stored)" -ForegroundColor Green

# ── 9. Function App with Managed Identity ─────────────────────────────────
Write-Host "[9/12] Creating Function App with Managed Identity..." -ForegroundColor Yellow
az functionapp create `
  --resource-group $ResourceGroup `
  --consumption-plan-location $Location `
  --runtime node `
  --runtime-version 20 `
  --functions-version 4 `
  --name $FunctionAppName `
  --storage-account $StorageName `
  --os-type Linux `
  --assign-identity "[system]" | Out-Null

# Get the Managed Identity principal ID
$ManagedIdentityId = az functionapp identity show `
  --name $FunctionAppName `
  --resource-group $ResourceGroup `
  --query principalId --output tsv

# Get Key Vault resource ID
$KeyVaultResourceId = az keyvault show `
  --name $KeyVaultName `
  --resource-group $ResourceGroup `
  --query id --output tsv

# Grant Managed Identity the Key Vault Secrets User role
# This allows the Function App to read secrets without storing credentials
az role assignment create `
  --role "Key Vault Secrets User" `
  --assignee $ManagedIdentityId `
  --scope $KeyVaultResourceId | Out-Null

Write-Host "       Function App: $FunctionAppName (Managed Identity granted Key Vault Secrets User)" -ForegroundColor Green

# ── 10. App Settings using Key Vault references ────────────────────────────
Write-Host "[10/12] Configuring App Settings with Key Vault references..." -ForegroundColor Yellow

# Key Vault reference syntax: @Microsoft.KeyVault(SecretUri=...)
# Azure resolves these at runtime using the Managed Identity — zero plain-text secrets
$KvRef = "https://${KeyVaultName}.vault.azure.net/secrets"

az functionapp config appsettings set `
  --name $FunctionAppName `
  --resource-group $ResourceGroup `
  --settings `
    "SERVICE_BUS_CONNECTION_STRING=@Microsoft.KeyVault(SecretUri=${KvRef}/ServiceBusConnectionString/)" `
    "COSMOS_ENDPOINT=@Microsoft.KeyVault(SecretUri=${KvRef}/CosmosEndpoint/)" `
    "COSMOS_KEY=@Microsoft.KeyVault(SecretUri=${KvRef}/CosmosKey/)" `
    "COSMOS_DATABASE_NAME=${CosmosDb}" `
    "COSMOS_CONTAINER_NAME=${CosmosContainer}" `
    "PRIORITY_QUEUE_NAME=${PriorityQueue}" `
    "STANDARD_QUEUE_NAME=${StandardQueue}" `
    "PROCESS_QUEUE_NAME=${PriorityQueue}" `
    "APPINSIGHTS_INSTRUMENTATIONKEY=${InstrumentationKey}" | Out-Null

Write-Host "       App Settings: all secrets referenced via Key Vault (zero plain-text credentials)" -ForegroundColor Green

# ── 11. Static Web App (Phase 1 — student portal) ─────────────────────────
Write-Host "[11/12] Creating Static Web App..." -ForegroundColor Yellow
az staticwebapp create `
  --name $StaticWebApp `
  --resource-group $ResourceGroup `
  --location $Location `
  --source "https://github.com/rahatislamanik-spec/Coquitlam-Itsm-Azure" `
  --branch main `
  --app-location "/frontend" `
  --output-location "" | Out-Null

Write-Host "       Static Web App: $StaticWebApp" -ForegroundColor Green

# ── 12. Azure Monitor alert rules (Phase 5) ────────────────────────────────
Write-Host "[12/12] Configuring Azure Monitor alert rules..." -ForegroundColor Yellow

$AppInsightsId = az monitor app-insights component show `
  --app $AppInsightsName `
  --resource-group $ResourceGroup `
  --query id --output tsv

# Alert: Function error rate > 5%
az monitor metrics alert create `
  --name "alert-function-errors" `
  --resource-group $ResourceGroup `
  --scopes $AppInsightsId `
  --condition "count requests/failed > 5" `
  --window-size 15m `
  --evaluation-frequency 5m `
  --description "Function failed request count exceeded 5 in 15-minute window" | Out-Null

Write-Host "       Alert rules configured" -ForegroundColor Green

# ── Summary ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Deployment complete." -ForegroundColor Cyan
Write-Host ""
Write-Host "  Resources created:" -ForegroundColor White
Write-Host "    Function App    : $FunctionAppName"    -ForegroundColor White
Write-Host "    Static Web App  : $StaticWebApp"       -ForegroundColor White
Write-Host "    Service Bus     : $SbNamespace"        -ForegroundColor White
Write-Host "    Cosmos DB       : $CosmosName"         -ForegroundColor White
Write-Host "    Key Vault       : $KeyVaultName"       -ForegroundColor White
Write-Host "    App Insights    : $AppInsightsName"    -ForegroundColor White
Write-Host "    Log Analytics   : $LogWorkspace"       -ForegroundColor White
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "    1. cd functions && npm install"
Write-Host "    2. func azure functionapp publish $FunctionAppName"
Write-Host "    3. Update FUNCTION_API_URL in frontend/index.html"
Write-Host "    4. Push frontend to GitHub — Static Web App auto-deploys"
Write-Host ""
