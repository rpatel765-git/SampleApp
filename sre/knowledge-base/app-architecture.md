# Team Task Tracker — Application Architecture Reference
## Node.js/TypeScript Express API on Azure Container Apps

**Version:** 1.0  
**Last Updated:** 2025-01-15  
**Maintained By:** Backend & SRE Teams

---

## 1. Application Overview

### What is Team Task Tracker?
Team Task Tracker is a RESTful API backend for managing tasks within teams. It provides endpoints for creating, reading, updating, and deleting tasks, along with health checks and monitoring capabilities.

### Technology Stack
| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Runtime** | Node.js | 18+ LTS | JavaScript execution engine |
| **Language** | TypeScript | 5.0+ | Type-safe development with compile-time checking |
| **Framework** | Express.js | 4.18+ | Web server and routing framework |
| **Test Runner** | Jest | 29.0+ | Unit, integration, and end-to-end testing |
| **Container** | Docker | Latest | Application packaging and deployment |
| **Platform** | Azure Container Apps | Latest | Managed container orchestration service |
| **Database** | SQL Server / PostgreSQL | Latest | Persistent data storage (configurable) |

### Architecture Diagram
```
┌─────────────────────────────────────────────────────┐
│           Azure Container Apps (Ingress)            │
│               (Load Balancer, HTTPS)                │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│         Express.js Application Instance              │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Middleware Layer                               │ │
│  │  ├─ CORS Handling                              │ │
│  │  ├─ Request Logging                            │ │
│  │  ├─ Body Parsing (JSON)                        │ │
│  │  └─ Error Handling                             │ │
│  └─────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Route Handlers                                 │ │
│  │  ├─ GET    /health                             │ │
│  │  ├─ GET    /api/tasks                          │ │
│  │  ├─ GET    /api/tasks/:id                      │ │
│  │  ├─ POST   /api/tasks                          │ │
│  │  ├─ PUT    /api/tasks/:id                      │ │
│  │  └─ DELETE /api/tasks/:id                      │ │
│  └─────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Business Logic Layer (Services)                │ │
│  │  ├─ Task Service                               │ │
│  │  │  ├─ getTasks()                              │ │
│  │  │  ├─ getTaskById(id)                         │ │
│  │  │  ├─ createTask(data)                        │ │
│  │  │  ├─ updateTask(id, data)                    │ │
│  │  │  └─ deleteTask(id)                          │ │
│  │  └─ Validation Service                         │ │
│  └─────────────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Data Access Layer (Models)                     │ │
│  │  └─ Task Model (ORM / Query Builder)           │ │
│  └─────────────────────────────────────────────────┘ │
└─────────────────────────┬────────────────────────────┘
                          │
                          ▼
            ┌──────────────────────────┐
            │  SQL Database (Azure)    │
            │  team_tasks_db           │
            └──────────────────────────┘
```

---

## 2. API Endpoints Reference

### Endpoint Summary Table

| HTTP Method | Endpoint | Purpose | Auth | Response Status |
|------------|----------|---------|------|-----------------|
| **GET** | `/health` | Health check / readiness probe | None | 200 / 503 |
| **GET** | `/api/tasks` | Retrieve all tasks (paginated) | Optional | 200 / 400 / 500 |
| **GET** | `/api/tasks/:id` | Retrieve single task by ID | Optional | 200 / 404 / 500 |
| **POST** | `/api/tasks` | Create new task | Required* | 201 / 400 / 409 / 500 |
| **PUT** | `/api/tasks/:id` | Update existing task | Required* | 200 / 400 / 404 / 409 / 500 |
| **DELETE** | `/api/tasks/:id` | Delete task by ID | Required* | 204 / 404 / 500 |

*Authentication: `*` = currently optional, future implementations may require Bearer token

### Endpoint Specifications

#### 1. GET /health
**Purpose:** Liveness and readiness probe for orchestrator  
**Query Parameters:** None  
**Response (200 OK):**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:30:00Z",
  "uptime": 3600,
  "checks": {
    "database": "connected",
    "memory": "normal",
    "diskSpace": "available"
  }
}
```
**Response (503 Service Unavailable):**
```json
{
  "status": "unhealthy",
  "timestamp": "2025-01-15T10:30:00Z",
  "checks": {
    "database": "disconnected"
  }
}
```

#### 2. GET /api/tasks
**Purpose:** Retrieve all tasks with optional filtering and pagination  
**Query Parameters:**
```
?status=pending|completed|archived
?assignee=<user_id>
?sortBy=createdAt|dueDate|priority
?sortOrder=asc|desc
?limit=10
?offset=0
```
**Response (200 OK):**
```json
{
  "data": [
    {
      "id": "task-001",
      "title": "Implement user auth",
      "description": "Add JWT-based authentication",
      "status": "in_progress",
      "priority": "high",
      "assignee": "user-123",
      "dueDate": "2025-01-20",
      "createdAt": "2025-01-15T10:00:00Z",
      "updatedAt": "2025-01-15T10:15:00Z"
    }
  ],
  "pagination": {
    "total": 42,
    "offset": 0,
    "limit": 10,
    "hasMore": true
  }
}
```

#### 3. GET /api/tasks/:id
**Purpose:** Retrieve single task by ID  
**URL Parameters:** `id` (string, required)  
**Response (200 OK):**
```json
{
  "id": "task-001",
  "title": "Implement user auth",
  "description": "Add JWT-based authentication",
  "status": "in_progress",
  "priority": "high",
  "assignee": "user-123",
  "dueDate": "2025-01-20",
  "createdAt": "2025-01-15T10:00:00Z",
  "updatedAt": "2025-01-15T10:15:00Z"
}
```
**Response (404 Not Found):**
```json
{
  "error": "Task not found",
  "taskId": "task-001"
}
```

#### 4. POST /api/tasks
**Purpose:** Create new task  
**Request Body (JSON):**
```json
{
  "title": "Implement database migrations",
  "description": "Set up schema for users table",
  "priority": "high",
  "dueDate": "2025-01-25",
  "assignee": "user-456"
}
```
**Response (201 Created):**
```json
{
  "id": "task-new-001",
  "title": "Implement database migrations",
  "status": "pending",
  "createdAt": "2025-01-15T11:00:00Z"
}
```
**Response (400 Bad Request):**
```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "title",
      "message": "Title is required and must be 1-500 characters"
    }
  ]
}
```

#### 5. PUT /api/tasks/:id
**Purpose:** Update existing task  
**URL Parameters:** `id` (string, required)  
**Request Body (JSON):**
```json
{
  "status": "completed",
  "priority": "normal"
}
```
**Response (200 OK):**
```json
{
  "id": "task-001",
  "title": "Implement user auth",
  "status": "completed",
  "priority": "normal",
  "updatedAt": "2025-01-15T12:00:00Z"
}
```

#### 6. DELETE /api/tasks/:id
**Purpose:** Delete task permanently  
**URL Parameters:** `id` (string, required)  
**Response (204 No Content):** (Empty body)  
**Response (404 Not Found):**
```json
{
  "error": "Task not found",
  "taskId": "task-001"
}
```

---

## 3. Key Files Reference Table

| File | Responsibility | Owner |
|------|-----------------|-------|
| `src/index.ts` | App initialization, middleware registration | Backend |
| `src/routes/tasks.ts` | HTTP request routing, request validation | Backend |
| `src/middleware/errorHandler.ts` | Global error handling, response formatting | Backend/SRE |
| `src/services/taskService.ts` | Business logic, data transformation | Backend |
| `src/config/environment.ts` | Configuration management, validation | DevOps/Backend |
| `Dockerfile` | Container image building, runtime setup | DevOps/SRE |
| `tsconfig.json` | TypeScript compiler settings | Backend |
| `jest.config.js` | Test runner configuration | Backend/QA |
| `package.json` | Dependencies, build scripts | Backend |

---

## 4. Deployment Configuration

### Azure Container Apps Specifications

| Configuration | Value | Details |
|---------------|-------|---------|
| **Container App Name** | team-task-tracker-ca | Azure resource name |
| **Resource Group** | rg-sre-demos | Azure resource group |
| **CPU per Replica** | 0.5-1.0 cores | Compute allocation |
| **Memory per Replica** | 512MB-1GB | RAM allocation |
| **Min Replicas** | 1 | Minimum instances running |
| **Max Replicas** | 3 | Maximum instances for auto-scaling |
| **Target CPU** | 70% | CPU threshold for scaling |
| **Internal Port** | 3000 | Container listening port |
| **Image Registry** | registry.azurecr.io | Azure Container Registry |
| **Image Name** | team-task-tracker | Container image name |
| **Image Tag** | latest | Current production tag |

### Container Scaling Policy
| Metric | Threshold | Action |
|--------|-----------|--------|
| CPU Usage | >70% sustained for 2min | Scale up (add replica) |
| Memory Usage | >80% of limit | Alert & review code |
| Request Count | >100 concurrent | Scale up |
| Min Replicas | 1 | Ensures availability |
| Max Replicas | 3 | Cost control |

### Multi-Stage Docker Build
```dockerfile
# Build stage: Compile TypeScript
FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Runtime stage: Minimal production image
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]
```

---

## 5. Environment Variables Reference

### Configuration Table

| Variable | Purpose | Type | Example | Required | Source |
|----------|---------|------|---------|----------|--------|
| `NODE_ENV` | Execution environment | string | `production` | Yes | Container config |
| `PORT` | HTTP server listen port | number | `3000` | No | Default: 3000 |
| `LOG_LEVEL` | Logging verbosity | string | `info` | No | Default: `info` |
| `DATABASE_HOST` | Database hostname | string | `server.database.windows.net` | Yes | Key Vault |
| `DATABASE_PORT` | Database connection port | number | `1433` | Yes | Key Vault |
| `DATABASE_USER` | Database login username | string | `sa` | Yes | Key Vault |
| `DATABASE_PASSWORD` | Database login password | string | `***` | Yes | Key Vault |
| `DATABASE_NAME` | Database schema name | string | `team_tasks_db` | Yes | Container config |
| `DATABASE_POOL_SIZE` | Connection pool size | number | `10` | No | Default: 10 |
| `DATABASE_TIMEOUT` | Query timeout (ms) | number | `30000` | No | Default: 30000 |
| `CORS_ORIGIN` | Allowed CORS origin | string | `https://app.example.com` | No | Container config |
| `JWT_SECRET` | JWT signing secret | string | `***` | Conditional | Key Vault |
| `JWT_EXPIRY` | JWT token TTL | string | `24h` | No | Default: `24h` |
| `APPLICATION_INSIGHTS_KEY` | App Insights instrumentation key | string | `***` | No | Key Vault |
| `ENABLE_METRICS` | Enable metrics collection | boolean | `true` | No | Default: `true` |

### Environment Variable Loading Priority
```
1. System environment variables (Container App)
2. Azure Key Vault secrets (referenced securely)
3. .env file (development only)
4. Default values in code (src/config/environment.ts)
```

---

## 6. GitHub Repository Information

### Repository Metadata

| Field | Value | Details |
|-------|-------|---------|
| **Organization** | your-org | GitHub organization |
| **Repository** | team-task-tracker | Repo name |
| **Main Branch** | `main` | Protected, requires PR review |
| **Development Branch** | `develop` | Feature branch base |
| **Default Visibility** | Private | Internal to organization |
| **Latest Release** | v1.0.0 | Current production version |

### Issue Labels
```
sre-agent-detected          → Auto-labeled when errors spike
type:bug                    → Bug reports
type:feature                → Feature requests
type:documentation          → Documentation updates
backend:task-service        → Task business logic
backend:routes              → HTTP route handlers
backend:middleware          → Middleware/error handling
backend:database            → Database queries
infra:docker                → Docker build/config
infra:deployment            → Container Apps deployment
infra:monitoring            → Logging/metrics
perf:memory-leak            → Suspected memory leak
perf:slow-query             → Database performance
security:dependency         → Dependency vulnerability
p1:critical                 → Production-blocking
p2:high                     → High priority
p3:medium                   → Medium priority
p4:low                      → Low priority
```

---

## 7. Key Monitoring Metrics

### SLA & Performance Targets

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| **Availability** | 99.9% | 99.5% | <99% |
| **Error Rate (5xx)** | <0.1% | >1% | >5% |
| **Response Time (P95)** | <500ms | >1000ms | >5000ms |
| **Response Time (P99)** | <1000ms | >2000ms | >5000ms |
| **CPU Usage** | <50% | >70% | >90% |
| **Memory Usage** | <60% | >75% | >95% |
| **Container Restarts** | 0/day | 2+/hour | 5+/hour |

### KQL Query Examples
```kql
// Error rate last 24 hours
requests
| where AppName == "team-task-tracker-ca"
| where Timestamp > ago(24h)
| summarize
    TotalRequests = count(),
    ErrorCount = count(resultCode startswith "5"),
    ErrorRate = (count(resultCode startswith "5") * 100.0 / count())

// Response time percentiles
requests
| where AppName == "team-task-tracker-ca"
| where Timestamp > ago(1h)
| summarize
    P50 = percentile(DurationMs, 50),
    P95 = percentile(DurationMs, 95),
    P99 = percentile(DurationMs, 99)
```

---

## 8. Development Workflow

### Local Development Commands
```bash
# Install dependencies
npm install

# Run in development mode (with hot reload)
npm run dev

# Run tests
npm run test

# Build TypeScript
npm run build

# Lint code
npm run lint
```

### Docker Local Testing
```bash
# Build image
docker build -t team-task-tracker:latest .

# Run container
docker run -p 3000:3000 \
  -e DATABASE_HOST=localhost \
  -e DATABASE_USER=sa \
  -e DATABASE_PASSWORD=Password \
  team-task-tracker:latest
```

---

## 9. Troubleshooting Quick Reference

| Issue | Root Cause | Solution |
|-------|-----------|----------|
| Port already in use | Another process on port 3000 | `lsof -i :3000` and kill or change PORT |
| Module not found | Missing npm install or build | Run `npm install && npm run build` |
| Database connection refused | Database down or wrong credentials | Check DATABASE_HOST, DATABASE_USER |
| Tests fail locally | Database not running | Start database or mock in tests |
| Docker build fails | npm install fails | Check Dockerfile, verify package compatibility |

---

## 10. Contact & Resources

### Team Contacts
- **Backend Lead:** backend-lead@company.com
- **DevOps/SRE:** sre@company.com
- **On-Call:** Check PagerDuty

### Related Documentation
- [Error Investigation Runbook](./error-investigation-runbook.md)
- [Deployment Guide](../deployment/README.md)
- [Local Development Setup](../../README.md)

---

**Last Updated:** 2025-01-15  
**Maintained By:** Backend & SRE Teams
