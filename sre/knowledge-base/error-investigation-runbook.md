# Error Investigation Runbook
## Team Task Tracker — Express.js/TypeScript on Azure Container Apps

**Last Updated:** 2025-01-15  
**Audience:** SRE Team, On-Call Engineers  
**Escalation Path:** L1 SRE → L2 Backend Team → Platform Engineering

---

## 1. Trigger Keywords & Scope

### Trigger Keywords
- `500 Internal Server Error`
- `Internal server error` / `Internal Server Error`
- `timeout` / `request timeout` / `connection timeout`
- `crash` / `crashed` / `crashing`
- `OOM` / `out of memory` / `memory limit exceeded`
- `EADDRINUSE` (port conflict)
- `ECONNREFUSED` (connection refused)
- `ENOTFOUND` (DNS resolution failure)

### Scope
- **Application:** Team Task Tracker (Task Management Backend)
- **Technology Stack:** Node.js 18+, TypeScript, Express.js, Jest
- **Deployment Platform:** Azure Container Apps
- **Monitored Components:** Express API, health check endpoint, task routes, database layer
- **Primary Language:** TypeScript (compiled to JavaScript at runtime)

---

## 2. Application Architecture Summary

### High-Level Overview
Team Task Tracker is a RESTful API backend for task management built with:
- **Express.js** — HTTP server framework
- **TypeScript** — Type-safe development with compile-time checking
- **Jest** — Test framework for unit and integration tests
- **Azure Container Apps** — Containerized deployment with auto-scaling

### API Layer
- Health Check: `/health` (GET) — Validates container and basic dependencies
- Task CRUD Operations: `/api/tasks` (GET, POST, PUT, DELETE)
- Error Handling Middleware: Global error handler catches unhandled rejections and sync errors

### Key Files Structure
```
SampleApp/
├── src/
│   ├── index.ts                 # Entry point, Express app initialization
│   ├── routes/
│   │   ├── tasks.ts            # Task CRUD routes
│   │   └── health.ts           # Health check route
│   ├── middleware/
│   │   ├── errorHandler.ts     # Global error handling
│   │   ├── logging.ts          # Request/response logging
│   │   └── cors.ts             # CORS configuration
│   ├── models/
│   │   └── Task.ts             # Task data model & validation
│   ├── services/
│   │   └── taskService.ts      # Business logic layer
│   ├── config/
│   │   └── environment.ts      # Environment variable loading
│   └── types/
│       └── index.ts            # TypeScript type definitions
├── tests/
│   ├── unit/                   # Unit tests
│   ├── integration/            # Integration tests
│   └── e2e/                    # End-to-end tests
├── Dockerfile                  # Container image definition
├── tsconfig.json              # TypeScript compilation config
├── jest.config.js             # Test configuration
└── package.json               # Dependencies & scripts
```

### Deployment Configuration
- **Container Image:** `registry.azurecr.io/team-task-tracker:latest`
- **Container App Name:** `team-task-tracker-ca`
- **Resource Group:** `rg-sre-demos`
- **CPU:** 0.5-1.0 cores per replica
- **Memory:** 512MB-1GB per replica
- **Min Replicas:** 1
- **Max Replicas:** 3 (with target CPU utilization 70%)
- **Port:** 3000 (internal), exposed via ingress

---

## 3. Phase 1: Initial Triage

### Step 1.1: Check Container App Status
```bash
# Using Azure CLI
az containerapp show --resource-group rg-sre-demos --name team-task-tracker-ca \
  --query "properties.runningStatus" -o tsv

# Expected output: Running or Degraded or Provisioning_Failed
```

**What to look for:**
- Status: `Running` (healthy) vs. `Degraded` or `Provisioning_Failed` (unhealthy)
- If degraded: check `az containerapp replica list` for failed replicas

### Step 1.2: Retrieve Recent Application Logs
```kql
// KQL Query: Fetch last 100 logs from container (last 30 minutes)
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "team-task-tracker-ca"
| where TimeGenerated > ago(30m)
| project TimeGenerated, ContainerAppName_s, Log_s
| order by TimeGenerated desc
| limit 100
```

**Parsing log output:**
- Look for `ERROR`, `FATAL`, `[error]`, `Exception`, `Stack trace`
- Identify timestamp and error message prefix

### Step 1.3: Quick Error Count (Last 1 Hour)
```kql
// Count HTTP 500 errors in the last hour
requests
| where AppName == "team-task-tracker-ca"
| where resultCode == "500"
| where Timestamp > ago(1h)
| summarize ErrorCount = count() by bin(Timestamp, 5m)
| order by Timestamp desc
```

**Expected baseline:** 0–5 errors/hour under normal load  
**Warning threshold:** 10+ errors/5min → escalate to Phase 2

### Step 1.4: Container Restart Events
```kql
// Check for recent container restarts
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "team-task-tracker-ca"
| where Log_s contains "listening" or Log_s contains "started"
| where TimeGenerated > ago(2h)
| order by TimeGenerated desc
| limit 10
```

**Interpretation:**
- Multiple "listening" messages in short time = container restarts
- Compare restart timestamps with error spike timestamps

---

## 4. Phase 2: Error Pattern Analysis

### Step 2.1: Top Errors by Message (Last 4 Hours)
```kql
// Identify recurring error patterns
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "team-task-tracker-ca"
| where TimeGenerated > ago(4h)
| where Log_s contains "error" or Log_s contains "Error" or Log_s contains "ERROR"
| extract "(?i)error:\s*(?<ErrorMsg>[^\n]+)" from Log_s
| summarize Count = count(), LastSeen = max(TimeGenerated) by ErrorMsg
| order by Count desc
| limit 10
```

**Analysis:**
- Group errors by message → identify clusters
- If same error repeats 10+ times → likely systematic issue, not transient

### Step 2.2: Error Rate Over Time (Granular 5-Minute Buckets)
```kql
// Track error rate progression to detect spike patterns
requests
| where AppName == "team-task-tracker-ca"
| where resultCode startswith "5"  // 5xx errors
| where Timestamp > ago(24h)
| summarize 
    ErrorCount = count(),
    AvgResponseTime = avg(DurationMs),
    P95ResponseTime = percentile(DurationMs, 95),
    UniqueUsers = dcount(UserId)
  by bin(Timestamp, 5m)
| order by Timestamp desc
```

**Decision Tree:**
- If errors cluster at specific times → check scheduled jobs, batch operations, or traffic spikes
- If errors are sporadic → likely external dependency issue (database, network)
- If errors gradually increase → likely resource exhaustion or memory leak

### Step 2.3: Errors by Route/Endpoint
```kql
// Which API endpoints are failing most?
requests
| where AppName == "team-task-tracker-ca"
| where resultCode startswith "5"
| where Timestamp > ago(4h)
| summarize 
    FailureCount = count(),
    AvgDuration = avg(DurationMs),
    MaxDuration = max(DurationMs)
  by Url, resultCode
| order by FailureCount desc
```

**Root cause clues:**
- `/api/tasks` POST failures → validation or database write issue
- `/api/tasks/:id` GET failures → data retrieval or formatting issue
- `/health` failures → dependency check failed (very bad — app unhealthy)

---

## 5. Phase 3: Common Root Causes & Diagnostics

### Root Cause #1: Unhandled Promise Rejection in Route Handlers

**Symptoms:**
- `UnhandledPromiseRejection` in logs
- Server crashes with no HTTP error response sent
- Client receives connection reset

**KQL Diagnostic Query:**
```kql
// Search for unhandled promise rejections
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "team-task-tracker-ca"
| where TimeGenerated > ago(2h)
| where Log_s contains "UnhandledPromiseRejection" 
   or Log_s contains "unhandledRejection"
   or Log_s contains "Promise rejection"
| project TimeGenerated, Log_s
| order by TimeGenerated desc
```

**Investigation Steps:**
1. Identify which route handler last executed before crash (check logs before rejection)
2. Check `/SampleApp/src/routes/tasks.ts` for missing `.catch()` or `await` errors
3. Look for async functions without `try-catch` blocks

**Common Code Pattern (BUG):**
```typescript
// ❌ WRONG: Async route handler without await
app.post('/api/tasks', (req, res) => {
  someAsyncFunction(); // Fire and forget → rejection will crash server
  res.json({ success: true });
});
```

**Fix:**
```typescript
// ✅ CORRECT: Wrap in try-catch or .catch()
app.post('/api/tasks', async (req, res) => {
  try {
    const result = await someAsyncFunction();
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

### Root Cause #2: Database Connection Failures

**Symptoms:**
- Errors like `ECONNREFUSED`, `connection timeout`, `socket hang up`
- POST/PUT/DELETE requests fail; GET requests may still work (if cached)
- Spikes correlate with database maintenance windows

**KQL Diagnostic Query:**
```kql
// Search for database connection errors
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "team-task-tracker-ca"
| where TimeGenerated > ago(4h)
| where Log_s contains "ECONNREFUSED" 
   or Log_s contains "connection timeout"
   or Log_s contains "socket hang up"
   or Log_s contains "getaddrinfo"
| summarize Count = count() by bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```

**Investigation Steps:**
1. Check if database is running: `az sql server show --resource-group rg-sre-demos --name team-task-tracker-sql`
2. Check database connection string in environment variables (verify hostname, port, credentials)
3. Check database firewall rules allow Container App's network

**Environment Variables to Verify:**
```
DATABASE_HOST=team-task-tracker-sql.database.windows.net
DATABASE_PORT=1433
DATABASE_USER=sa
DATABASE_PASSWORD=*** (check in Key Vault)
DATABASE_NAME=team_tasks_db
```

### Root Cause #3: TypeScript Compilation Errors in Production

**Symptoms:**
- `SyntaxError: Unexpected token` in logs
- `TypeError: Cannot read property X of undefined`
- Errors reference `.js` files that don't match TypeScript source
- Container crashes during startup

**KQL Diagnostic Query:**
```kql
// Search for syntax and compilation errors
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "team-task-tracker-ca"
| where TimeGenerated > ago(2h)
| where Log_s contains "SyntaxError" 
   or Log_s contains "TypeError"
   or Log_s contains "is not a function"
   or Log_s contains "compiled"
| project TimeGenerated, Log_s
| order by TimeGenerated desc
```

**Investigation Steps:**
1. Check if TypeScript compilation succeeded during Docker build:
   ```bash
   docker build -t team-task-tracker:test .
   # Look for "npm run build" output — should complete without errors
   ```
2. Verify `tsconfig.json` settings (check `esModuleInterop`, `lib`, `target`)
3. Check for missing type definitions: `npm ls @types/*` in production build

**Common Issue:**
```typescript
// ❌ WRONG: Missing await on async function
const tasks = taskService.getTasks(); // Returns Promise<Task[]>, not Task[]
tasks.map(t => t.id); // TypeError: tasks.map is not a function
```

### Root Cause #4: Memory Leaks / Out of Memory Kills

**Symptoms:**
- `OOMKilled` in container logs
- Memory usage steadily increases until container restarts
- Occurs after several hours of uptime
- Happens after specific operations (e.g., bulk uploads)

**KQL Diagnostic Query:**
```kql
// Monitor memory usage trend
// (Note: Requires memory metrics to be collected)
ContainerAppMetrics_CL
| where ContainerAppName_s == "team-task-tracker-ca"
| where TimeGenerated > ago(24h)
| where MetricName == "Memory Usage MB"
| summarize 
    AvgMemory = avg(MetricValue),
    MaxMemory = max(MetricValue),
    MinMemory = min(MetricValue)
  by bin(TimeGenerated, 10m)
| order by TimeGenerated desc
```

**Investigation Steps:**
1. Check for unbounded loops or growing data structures in `/SampleApp/src/services/`
2. Look for event listeners not being removed (`removeListener`, `off`)
3. Check for circular references in cached objects
4. Review `/SampleApp/src/routes/tasks.ts` for operations loading entire datasets into memory

**Memory Leak Pattern (Example):**
```typescript
// ❌ WRONG: Global cache without size limit
const cache = {};
app.get('/api/tasks', (req, res) => {
  cache[Date.now()] = new Array(1000000); // Grows indefinitely
  res.json(cache);
});
```

### Root Cause #5: Port Mismatch in Container Config

**Symptoms:**
- Container starts but no requests reach app
- `Connection refused` from ingress
- Container status shows `Running` but unreachable

**KQL Diagnostic Query:**
```kql
// Check for port binding errors
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "team-task-tracker-ca"
| where Log_s contains "listening" or Log_s contains "EADDRINUSE"
| project TimeGenerated, Log_s
| order by TimeGenerated desc
| limit 5
```

**Investigation Steps:**
1. Verify Container App ingress port matches app listen port:
   ```bash
   az containerapp show --resource-group rg-sre-demos --name team-task-tracker-ca \
     --query "properties.configuration.ingress"
   ```
   Expected: `targetPort: 3000`

2. Check environment variable for PORT override:
   ```bash
   echo $PORT  # Should be 3000 or empty (defaults to 3000)
   ```

3. Verify `src/index.ts` listens on correct port:
   ```typescript
   const PORT = process.env.PORT || 3000;
   app.listen(PORT, () => console.log(`listening on port ${PORT}`));
   ```

---

## 6. Phase 4: Resource Health & Metrics

### Resource Health Thresholds

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| **CPU Usage** | >70% sustained | >90% for 5min | Scale up replicas or optimize code |
| **Memory Usage** | >75% of limit | >95% or OOMKilled | Check for leaks (Phase 3) |
| **Container Restarts** | 2+ in 1 hour | 5+ in 1 hour | Investigate crash cause |
| **Request Latency P95** | >1000ms | >5000ms | Check database query performance |
| **Error Rate (5xx)** | >1% | >5% | Immediate investigation required |
| **Replica Count** | N/A | Min replicas unreachable | Scaling or infrastructure issue |

### Check Current Resource Metrics
```kql
// Overall health snapshot (last 1 hour)
requests
| where AppName == "team-task-tracker-ca"
| where Timestamp > ago(1h)
| summarize 
    TotalRequests = count(),
    FailedRequests = count(resultCode startswith "5"),
    ErrorRate = (count(resultCode startswith "5") * 100.0 / count()),
    AvgResponseTime = avg(DurationMs),
    P95ResponseTime = percentile(DurationMs, 95),
    P99ResponseTime = percentile(DurationMs, 99)
```

### Monitor Replica Health
```bash
# Check replica status
az containerapp replica list --resource-group rg-sre-demos --name team-task-tracker-ca \
  --query "[].{Name:name, Status:status, CPUUsage:properties.runningState, Memory:properties.memoryUsage}"
```

### Container Restart History
```kql
// Track restart frequency
ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "team-task-tracker-ca"
| where Log_s contains "listening on port"  // Indicates app startup
| where TimeGenerated > ago(24h)
| summarize RestartCount = count(), 
            FirstRestart = min(TimeGenerated),
            LastRestart = max(TimeGenerated)
| project 
    RestartCount,
    TimeSpan = (LastRestart - FirstRestart),
    AvgRestartInterval = (LastRestart - FirstRestart) / RestartCount
```

---

## 7. Phase 5: GitHub Code Correlation

### Files Likely to Cause Errors (Review Recent Changes)

| File | Common Issues | Link |
|------|---------------|------|
| `src/routes/tasks.ts` | Unhandled promise rejections, missing error handlers | [View on GitHub](https://github.com/your-org/team-task-tracker/blob/main/src/routes/tasks.ts) |
| `src/middleware/errorHandler.ts` | Global error handling gaps, error serialization | [View on GitHub](https://github.com/your-org/team-task-tracker/blob/main/src/middleware/errorHandler.ts) |
| `src/services/taskService.ts` | Database queries, data transformation logic | [View on GitHub](https://github.com/your-org/team-task-tracker/blob/main/src/services/taskService.ts) |
| `src/models/Task.ts` | Validation logic, type mismatches | [View on GitHub](https://github.com/your-org/team-task-tracker/blob/main/src/models/Task.ts) |
| `src/index.ts` | Port binding, middleware setup, app initialization | [View on GitHub](https://github.com/your-org/team-task-tracker/blob/main/src/index.ts) |
| `Dockerfile` | Runtime configuration, port mapping, environment setup | [View on GitHub](https://github.com/your-org/team-task-tracker/blob/main/Dockerfile) |

### Quick Code Review Steps
1. **Check recent commits** in main/prod branch:
   ```bash
   git log --oneline --all -20 -- src/
   ```

2. **Identify code changes in last 24 hours:**
   ```bash
   git log --since="24 hours ago" --oneline --all -- src/
   ```

3. **Search for TODO/FIXME/BUG comments:**
   ```bash
   grep -r "TODO\|FIXME\|BUG" src/ --include="*.ts"
   ```

4. **Check test coverage of recent changes:**
   ```bash
   npm run test -- --coverage --changedSince=main
   ```

---

## 8. Escalation Decision Tree

```
Is container running?
├─ NO → Check Azure Container App status (Phase 1.1)
│       → Check for resource quota limits
│       → Restart container app
│
└─ YES → Is error rate > 5% in last 1 hour?
         ├─ NO → Monitor for patterns (Phase 2), document in incident log
         │
         └─ YES → Check Phase 3 root causes
                  ├─ Unhandled Promise Rejection? → ESCALATE: Backend Team
                  ├─ Database Connection Failed? → Check database status
                  ├─ TypeScript Compilation Error? → Redeploy from clean build
                  ├─ Memory Leak / OOM? → Trigger memory dump
                  ├─ Port Mismatch? → Update Container App config
                  └─ Unknown? → ESCALATE: Platform Engineering
```

---

## 9. Common Commands Reference

### Restart Application
```bash
az containerapp update --resource-group rg-sre-demos --name team-task-tracker-ca \
  --set properties.template.containers[0].image="registry.azurecr.io/team-task-tracker:latest"
```

### View Real-Time Logs (Last 50 Lines)
```bash
az containerapp logs show --resource-group rg-sre-demos --name team-task-tracker-ca \
  --container-name team-task-tracker --tail 50 --follow
```

### Manually Scale Replicas
```bash
az containerapp update --resource-group rg-sre-demos --name team-task-tracker-ca \
  --set properties.template.scale.minReplicas=2 properties.template.scale.maxReplicas=5
```

### Trigger Health Check
```bash
curl https://team-task-tracker-ca.azurecontainerapps.io/health
```

---

## 10. Incident Response Template

**Incident ID:** `[Auto-generated]`  
**Timestamp:** `[When detected]`  
**Severity:** SEV-1 / SEV-2 / SEV-3  
**Status:** Investigating / Resolved / Escalated  

**Timeline:**
- **[HH:MM]** Error spike detected (Phase 1)
- **[HH:MM]** Root cause identified
- **[HH:MM]** Mitigation applied
- **[HH:MM]** Incident resolved

**Root Cause:** (Link to Phase 3 diagnosis)  
**Mitigation:** (Action taken)  
**Prevention:** (Future safeguard)  
**Postmortem:** (Document lessons learned)

---

## 11. Related Documentation

- [Application Architecture Reference](./app-architecture.md)
- [Deployment Guide](../deployment/README.md)
- [Local Development Setup](../../README.md)
- [Jest Test Guide](../../tests/README.md)
