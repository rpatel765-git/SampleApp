# Team Task Tracker — SRE Knowledge Base

Welcome to the comprehensive SRE knowledge base for the Team Task Tracker application (Node.js/TypeScript Express on Azure Container Apps).

## 📚 Documentation Index

### 1. **Application Architecture Reference** — [`app-architecture.md`](./app-architecture.md)
Complete technical reference covering:
- Technology stack (Node.js 18, TypeScript 5, Express.js 4.18+, Jest)
- API endpoints table with request/response examples
- Directory structure and key files
- Azure Container Apps deployment configuration
- Environment variables reference
- GitHub repository metadata and automation rules
- Monitoring metrics and SLA targets
- Development workflow and troubleshooting

**Use this when:**
- Onboarding new team members
- Understanding application structure and dependencies
- Checking deployment configuration
- Verifying environment variables
- Understanding API contracts

---

### 2. **Error Investigation Runbook** — [`error-investigation-runbook.md`](./error-investigation-runbook.md)
Comprehensive step-by-step error diagnosis guide with:
- **Phase 1: Initial Triage** — Container app status, recent logs, error count KQL queries
- **Phase 2: Error Pattern Analysis** — Top errors, error rate trends, endpoint-specific failures
- **Phase 3: Common Root Causes** — 5 detailed diagnostic sections:
  - Unhandled promise rejections in route handlers (with code examples)
  - Database connection failures (connection pooling, timeouts)
  - TypeScript compilation errors in production
  - Memory leaks and OOM kills (monitoring & prevention)
  - Port mismatch in container configuration
- **Phase 4: Resource Health** — CPU/memory thresholds, replica monitoring, restart history
- **Phase 5: GitHub Code Correlation** — Files to check, recent changes, code review steps
- Escalation decision tree
- Common commands reference
- Incident response template

**Use this when:**
- Error spike detected in production
- 500 errors or crashes reported
- Container restarts increasing
- Memory or CPU usage spiking
- Need to investigate specific error patterns

---

## 🚀 Quick Start

### For On-Call Engineers (First Alert Response)
1. **Received alert about errors?** → Start with [Error Investigation Runbook - Phase 1](./error-investigation-runbook.md#3-phase-1-initial-triage)
2. **Container status unclear?** → Check Phase 1.1 container app status commands
3. **Need root cause?** → Jump to [Phase 3: Common Root Causes](./error-investigation-runbook.md#5-phase-3-common-root-causes--diagnostics)
4. **Ready to escalate?** → Use the [Escalation Decision Tree](./error-investigation-runbook.md#8-escalation-decision-tree)

### For New Team Members
1. **Understanding the app?** → Read [Application Overview](./app-architecture.md#1-application-overview) and [Tech Stack](./app-architecture.md#1-application-overview)
2. **API design?** → Check [Endpoint Summary Table](./app-architecture.md#2-api-endpoints-reference)
3. **File locations?** → Review [Key Files Reference](./app-architecture.md#3-key-files-reference-table)
4. **Local setup?** → See [Development Workflow](./app-architecture.md#8-development-workflow)

### For SRE/DevOps Teams
1. **Deployment config?** → [Container Apps Specifications](./app-architecture.md#4-deployment-configuration)
2. **Environment variables?** → [Configuration Table](./app-architecture.md#5-environment-variables-reference)
3. **Scaling policy?** → [Container Scaling Policy](./app-architecture.md#4-deployment-configuration)
4. **Monitoring alerts?** → [Key Monitoring Metrics](./app-architecture.md#7-key-monitoring-metrics)

---

## 🔍 KQL Queries Reference

### Quick Diagnostic Queries
All KQL queries for Azure Monitor are embedded in the runbook with direct copy-paste usage:

**From error-investigation-runbook.md:**
- Phase 1.3: Quick Error Count (last 1 hour)
- Phase 2.1: Top Errors by Message (last 4 hours)
- Phase 2.2: Error Rate Over Time (5-min buckets)
- Phase 2.3: Errors by Route/Endpoint
- Phase 3: Root cause-specific queries for each issue type
- Phase 4: Resource health snapshot

---

## 📞 Escalation Contacts

| Role | Contact | Escalation Path |
|------|---------|-----------------|
| **On-Call Engineer** | PagerDuty | First responder |
| **Backend Team** | backend-lead@company.com | Application logic issues |
| **DevOps/SRE** | sre@company.com | Infrastructure & deployment |
| **Database Admin** | dba@company.com | Database connection/performance issues |

---

## 🏗️ Architecture at a Glance

```
Client Request
    ↓
Azure Container Apps (Ingress/Load Balancer)
    ↓
Express.js Application (Node.js 18)
    ↓
Middleware Layer (CORS, Logging, Error Handling)
    ↓
Route Handlers (/health, /api/tasks/*)
    ↓
Service Layer (Business Logic, Validation)
    ↓
Data Access Layer (Task Model, ORM)
    ↓
SQL Database (Azure SQL Server / PostgreSQL)
```

---

## 📊 Health Check Endpoints

**Liveness Probe:** `GET /health`
- Returns 200 if app is running
- Returns 503 if dependencies (database) are unhealthy
- Used by Azure Container Apps for auto-restart

**API Status:** Check `/api/tasks` endpoint
- GET returns 200 if database connected
- Returns 500 if database or service layer error

---

## 🔧 Common Troubleshooting Commands

```bash
# Check container app status
az containerapp show --resource-group rg-sre-demos --name team-task-tracker-ca

# View real-time logs
az containerapp logs show --resource-group rg-sre-demos --name team-task-tracker-ca --tail 50 --follow

# Check replica health
az containerapp replica list --resource-group rg-sre-demos --name team-task-tracker-ca

# Restart container app
az containerapp update --resource-group rg-sre-demos --name team-task-tracker-ca \
  --set properties.template.containers[0].image="registry.azurecr.io/team-task-tracker:latest"

# Trigger health check
curl https://team-task-tracker-ca.azurecontainerapps.io/health
```

---

## 📝 Document Maintenance

| Document | Last Updated | Owner | Review Schedule |
|----------|--------------|-------|-----------------|
| error-investigation-runbook.md | 2025-01-15 | SRE Team | Quarterly |
| app-architecture.md | 2025-01-15 | Backend & DevOps | Bi-annually |
| README (this file) | 2025-01-15 | SRE Team | As-needed |

---

## 🔐 Security Notes

- **Secrets:** Database passwords stored in Azure Key Vault, never in code
- **Authentication:** Environment variables loaded at runtime from Container App config
- **Logs:** Contains non-sensitive error messages; check Key Vault for secret rotation
- **Database:** Connection strings must match Azure SQL firewall rules

---

## 🎓 Learning Resources

- [Express.js Documentation](https://expressjs.com/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Jest Testing Framework](https://jestjs.io/)
- [Azure Container Apps Docs](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Kusto Query Language (KQL) Reference](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/)

---

**Navigation:**
- [← Back to SampleApp](../../)
- [View error-investigation-runbook.md](./error-investigation-runbook.md)
- [View app-architecture.md](./app-architecture.md)

**Last Updated:** 2025-01-15  
**Maintained By:** SRE & Backend Teams
