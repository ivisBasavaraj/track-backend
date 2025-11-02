# Tool Life Tracking System - Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         TOOL LIFE TRACKING SYSTEM                    │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐         ┌──────────────────────┐
│   FLUTTER FRONTEND   │◄───────►│   NODE.JS BACKEND    │
│                      │  HTTP   │                      │
│  - Dashboard         │  REST   │  - Express Server    │
│  - Usage Entry       │   API   │  - MongoDB ODM       │
│  - Alerts            │         │  - Business Logic    │
│  - History           │         │  - Notifications     │
└──────────────────────┘         └──────────────────────┘
                                           │
                                           │
                                           ▼
                                 ┌──────────────────────┐
                                 │   MONGODB DATABASE   │
                                 │                      │
                                 │  - mastertools       │
                                 │  - toolusagelogs     │
                                 │  - toolalerts        │
                                 └──────────────────────┘
```

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USAGE RECORDING FLOW                         │
└─────────────────────────────────────────────────────────────────────┘

1. USER INPUT (Flutter)
   ├─ Component: AMS-141
   ├─ Tool ID: 5
   ├─ Holes: 43
   └─ Cutting Length: 23
          │
          ▼
2. API REQUEST
   POST /api/tool-life/usage/record
   {
     "tool_id": 5,
     "component_id": "AMS-141",
     "no_of_holes": 43,
     "cutting_length": 23
   }
          │
          ▼
3. BACKEND PROCESSING
   ├─ Get Master Tool (tool_id: 5)
   │  └─ tool_life_threshold: 3000
   │
   ├─ Get Current Cumulative Usage
   │  └─ Query latest ToolUsageLog
   │  └─ cumulative_total_after: 0
   │
   ├─ Calculate Usage Score
   │  └─ 43 × 23 = 989
   │
   ├─ Calculate New Cumulative
   │  └─ 0 + 989 = 989
   │
   ├─ Check Thresholds
   │  ├─ 90% threshold: 2700
   │  ├─ 100% threshold: 3000
   │  └─ Current: 989 (32.97%)
   │  └─ Status: ACTIVE ✓
   │
   ├─ Log Usage
   │  └─ Create ToolUsageLog entry
   │
   └─ Check Alert Needed
      └─ No (989 < 2700)
          │
          ▼
4. RESPONSE
   {
     "usage_score": 989,
     "cumulative_total": 989,
     "usage_percentage": "32.97",
     "remaining_life": 2011,
     "alert_type": "NONE",
     "status": "ACTIVE"
   }
          │
          ▼
5. UI UPDATE (Flutter)
   └─ Update progress bar
   └─ Show success message
   └─ Display new cumulative total
```

## Alert System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ALERT TRIGGER FLOW                           │
└─────────────────────────────────────────────────────────────────────┘

USAGE RECORDED
     │
     ▼
┌─────────────────────┐
│ Calculate Usage %   │
│ (cumulative/thresh) │
└─────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    THRESHOLD DECISION TREE                           │
└─────────────────────────────────────────────────────────────────────┘

Usage < 90%                Usage ≥ 90%              Usage ≥ 100%
     │                          │                         │
     ▼                          ▼                         ▼
┌──────────┐            ┌──────────────┐         ┌──────────────┐
│  ACTIVE  │            │   WARNING    │         │   CRITICAL   │
│          │            │              │         │              │
│ Status:  │            │ Status:      │         │ Status:      │
│ ACTIVE   │            │ NEAR_END_OF  │         │ END_OF_LIFE  │
│          │            │ _LIFE        │         │              │
│ Color:   │            │              │         │              │
│ Green    │            │ Color:       │         │ Color:       │
│          │            │ Orange       │         │ Red          │
│ Alert:   │            │              │         │              │
│ NO       │            │ Alert:       │         │ Alert:       │
│          │            │ YES (90%)    │         │ YES (100%)   │
└──────────┘            └──────────────┘         └──────────────┘
                               │                         │
                               ▼                         ▼
                        ┌──────────────┐         ┌──────────────┐
                        │ Create Alert │         │ Create Alert │
                        │ Type: WARNING│         │ Type: CRITICAL│
                        └──────────────┘         └──────────────┘
                               │                         │
                               ▼                         ▼
                        ┌──────────────┐         ┌──────────────┐
                        │ Send Email   │         │ Send Email   │
                        │ to Supervisor│         │ to Supervisor│
                        └──────────────┘         └──────────────┘
                               │                         │
                               ▼                         ▼
                        ┌──────────────┐         ┌──────────────┐
                        │ Status: SENT │         │ Status: SENT │
                        └──────────────┘         └──────────────┘
```

## Database Schema Relationships

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATABASE STRUCTURE                           │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│   MASTER TOOLS       │
│──────────────────────│
│ tool_id (PK)         │◄──────────┐
│ tool_name            │           │
│ holder_name          │           │
│ tool_life_threshold  │           │
│ status               │           │
│ supervisor_email     │           │
└──────────────────────┘           │
                                   │ (References)
                                   │
┌──────────────────────┐           │
│  TOOL USAGE LOGS     │           │
│──────────────────────│           │
│ _id (PK)             │           │
│ tool_id (FK)         │───────────┤
│ component_id         │           │
│ no_of_holes          │           │
│ cutting_length       │           │
│ usage_score          │           │
│ cumulative_total_    │           │
│   before             │           │
│ cumulative_total_    │           │
│   after              │           │
│ alert_type           │           │
│ timestamp            │           │
└──────────────────────┘           │
                                   │
┌──────────────────────┐           │
│   TOOL ALERTS        │           │
│──────────────────────│           │
│ _id (PK)             │           │
│ tool_id (FK)         │───────────┘
│ alert_type           │
│ cumulative_usage     │
│ components_used[]    │
│ alert_status         │
│ alert_message        │
│ created_date         │
│ sent_date            │
└──────────────────────┘
```

## Component Usage Tracking

```
┌─────────────────────────────────────────────────────────────────────┐
│              TOOL USAGE ACROSS MULTIPLE COMPONENTS                   │
└─────────────────────────────────────────────────────────────────────┘

TOOL ID: 5 (CARBIDE DRILL)
Threshold: 3000

Process 1: AMS-141 Column
┌────────────────────────────────────┐
│ Holes: 43                          │
│ Length: 23                         │
│ Score: 989                         │
│ Cumulative: 0 → 989                │
│ Status: ACTIVE (32.97%)            │
│ ████████░░░░░░░░░░░░░░░░░░░░       │
└────────────────────────────────────┘
              ↓
Process 2: AMS-915 Column
┌────────────────────────────────────┐
│ Holes: 50                          │
│ Length: 15                         │
│ Score: 750                         │
│ Cumulative: 989 → 1739             │
│ Status: ACTIVE (57.97%)            │
│ █████████████████░░░░░░░░░░░░░     │
└────────────────────────────────────┘
              ↓
Process 3: AMS-103 Column
┌────────────────────────────────────┐
│ Holes: 42                          │
│ Length: 30                         │
│ Score: 1260                        │
│ Cumulative: 1739 → 2999            │
│ Status: NEAR_END_OF_LIFE (99.97%)  │
│ ██████████████████████████████░    │
│ ⚠️  WARNING ALERT SENT             │
└────────────────────────────────────┘
              ↓
Process 4: AMS-477 Base
┌────────────────────────────────────┐
│ Holes: 1                           │
│ Length: 5                          │
│ Score: 5                           │
│ Cumulative: 2999 → 3004            │
│ Status: END_OF_LIFE (100.13%)      │
│ ███████████████████████████████    │
│ 🚨 CRITICAL ALERT SENT             │
└────────────────────────────────────┘
```

## API Endpoint Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         API ENDPOINTS                                │
└─────────────────────────────────────────────────────────────────────┘

BASE: /api/tool-life

┌──────────────────────────────────────────────────────────────────┐
│ MASTER TOOLS                                                     │
├──────────────────────────────────────────────────────────────────┤
│ POST   /master/create        Create new master tool             │
│ GET    /master/all           Get all master tools               │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ USAGE TRACKING                                                   │
├──────────────────────────────────────────────────────────────────┤
│ POST   /usage/record         Record tool usage                  │
│ GET    /:toolId/status       Get current tool status            │
│ GET    /:toolId/history      Get usage history                  │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ ALERTS                                                           │
├──────────────────────────────────────────────────────────────────┤
│ GET    /alerts/active        Get active alerts                  │
│ POST   /alerts/notify        Send notification (Supervisor)     │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ MAINTENANCE                                                      │
├──────────────────────────────────────────────────────────────────┤
│ POST   /:toolId/reset        Reset tool after maintenance       │
└──────────────────────────────────────────────────────────────────┘
```

## Flutter Screen Navigation

```
┌─────────────────────────────────────────────────────────────────────┐
│                      FLUTTER SCREEN FLOW                             │
└─────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────┐
                    │   Main Dashboard     │
                    │   (Supervisor/User)  │
                    └──────────────────────┘
                              │
                              ▼
                    ┌──────────────────────┐
                    │ Tool Life Dashboard  │
                    │                      │
                    │ - All Tools List     │
                    │ - Progress Bars      │
                    │ - Status Indicators  │
                    └──────────────────────┘
                         │    │    │
           ┌─────────────┘    │    └─────────────┐
           │                  │                  │
           ▼                  ▼                  ▼
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│ Tool Usage     │  │ Tool History   │  │ Tool Alerts    │
│ Entry          │  │                │  │                │
│                │  │ - Usage Logs   │  │ - WARNING      │
│ - Component    │  │ - Component    │  │ - CRITICAL     │
│ - Holes        │  │   Breakdown    │  │ - Components   │
│ - Length       │  │ - Cumulative   │  │ - Status       │
│ - Submit       │  │   Progress     │  │                │
└────────────────┘  └────────────────┘  └────────────────┘
```

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SECURITY LAYERS                              │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ Layer 1: Network Security                                        │
├──────────────────────────────────────────────────────────────────┤
│ - HTTPS (Production)                                             │
│ - CORS Configuration                                             │
│ - Rate Limiting                                                  │
│ - Helmet Security Headers                                        │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Layer 2: Authentication                                          │
├──────────────────────────────────────────────────────────────────┤
│ - JWT Token Validation                                           │
│ - User Session Management                                        │
│ - Token Expiration                                               │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Layer 3: Authorization                                           │
├──────────────────────────────────────────────────────────────────┤
│ - Role-Based Access Control                                      │
│ - Supervisor-Only Endpoints                                      │
│   • /master/create                                               │
│   • /alerts/notify                                               │
│   • /:toolId/reset                                               │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Layer 4: Data Validation                                         │
├──────────────────────────────────────────────────────────────────┤
│ - Input Sanitization                                             │
│ - Type Validation                                                │
│ - Range Checks                                                   │
│ - MongoDB Injection Prevention                                   │
└──────────────────────────────────────────────────────────────────┘
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      PRODUCTION DEPLOYMENT                           │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│   Mobile Devices     │
│   (Flutter App)      │
└──────────────────────┘
          │
          │ HTTPS
          ▼
┌──────────────────────┐
│   Load Balancer      │
│   (Optional)         │
└──────────────────────┘
          │
          ▼
┌──────────────────────┐
│   Node.js Server     │
│   (Express API)      │
│   Port: 3000         │
└──────────────────────┘
          │
          ▼
┌──────────────────────┐
│   MongoDB Database   │
│   (Replica Set)      │
└──────────────────────┘
          │
          ▼
┌──────────────────────┐
│   Email Service      │
│   (Nodemailer/SES)   │
└──────────────────────┘
```

## Performance Optimization

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PERFORMANCE STRATEGIES                            │
└─────────────────────────────────────────────────────────────────────┘

DATABASE LEVEL
├─ Indexes on tool_id, timestamp
├─ Compound indexes for queries
├─ Efficient aggregation pipelines
└─ Connection pooling

API LEVEL
├─ Minimal data transfer
├─ Pagination support
├─ Caching strategies
└─ Async/await patterns

FRONTEND LEVEL
├─ Lazy loading
├─ State management
├─ Debounced API calls
└─ Local caching
```

---

This architecture supports:
- ✅ Scalability (horizontal scaling)
- ✅ Reliability (error handling)
- ✅ Security (multi-layer)
- ✅ Performance (optimized queries)
- ✅ Maintainability (clean code)
