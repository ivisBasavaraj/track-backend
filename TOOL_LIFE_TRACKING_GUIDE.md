# Tool Life Tracking System - Implementation Guide

## Overview

This system implements accumulative tool life tracking that monitors tool usage across multiple components and sends dual-level notifications (WARNING at 90%, CRITICAL at 100%) to supervisors when thresholds are reached.

## System Architecture

### Backend (Node.js/Express)

#### Models Created

1. **MasterTool** (`models/MasterTool.js`)
   - Stores master tool information with life thresholds
   - Fields: tool_id, tool_name, holder_name, tool_life_threshold, status, supervisor_email

2. **ToolUsageLog** (`models/ToolUsageLog.js`)
   - Records every tool usage event
   - Tracks cumulative totals before/after each usage
   - Fields: tool_id, component_id, no_of_holes, cutting_length, usage_score, cumulative totals

3. **ToolAlert** (`models/ToolAlert.js`)
   - Stores alert notifications (WARNING/CRITICAL)
   - Tracks alert status (PENDING/SENT/ACKNOWLEDGED)
   - Fields: tool_id, alert_type, cumulative_usage, components_used, alert_message

#### API Endpoints

**Base URL:** `/api/tool-life`

1. **POST /usage/record**
   - Record tool usage and calculate cumulative total
   - Body: `{ tool_id, component_id, no_of_holes, cutting_length, operator_id }`
   - Returns: Usage score, cumulative total, alert status

2. **GET /:toolId/status**
   - Get current status of a tool
   - Returns: Cumulative usage, percentage, remaining life, alert status

3. **GET /alerts/active**
   - Get all active alerts (PENDING/SENT)
   - Returns: Array of active alerts

4. **POST /alerts/notify**
   - Send notification to supervisor (Supervisor only)
   - Body: `{ alert_id, supervisor_email }`

5. **POST /:toolId/reset**
   - Reset tool after maintenance (Supervisor only)
   - Body: `{ maintenance_notes, maintenance_date, technician_id }`

6. **POST /master/create**
   - Create master tool entry (Supervisor only)
   - Body: `{ tool_id, tool_name, tool_life_threshold, holder_name, supervisor_email }`

7. **GET /master/all**
   - Get all master tools with current usage

8. **GET /:toolId/history**
   - Get tool usage history

### Frontend (Flutter)

#### Models Created

1. **MasterTool** (`models/tool_life_model.dart`)
2. **ToolUsageLog**
3. **ToolAlert**
4. **ToolStatus**

#### Services Created

**ToolLifeService** (`services/tool_life_service.dart`)
- Handles all API calls for tool life tracking
- Methods: recordToolUsage, getToolStatus, getActiveAlerts, resetTool, etc.

#### Screens Created

1. **ToolLifeDashboardScreen** (`screens/tool_life_dashboard_screen.dart`)
   - Displays all tools with visual progress bars
   - Shows cumulative usage, percentage, remaining life
   - Color-coded status indicators (Green/Orange/Red)

2. **ToolUsageEntryScreen** (`screens/tool_usage_entry_screen.dart`)
   - Form to record tool usage
   - Component dropdown (AMS-141, AMS-915, AMS-103, AMS-477)
   - Input fields: Tool ID, Number of Holes, Cutting Length
   - Displays result after submission with alert dialogs

3. **ToolAlertsScreen** (`screens/tool_alerts_screen.dart`)
   - Lists all active alerts (WARNING/CRITICAL)
   - Color-coded by severity
   - Shows components affected and alert messages

4. **ToolLifeHistoryScreen** (`screens/tool_life_history_screen.dart`)
   - Displays usage history for a specific tool
   - Shows component-wise breakdown
   - Highlights alert-triggering events

## Usage Flow

### 1. Create Master Tool (One-time Setup)

```bash
POST /api/tool-life/master/create
{
  "tool_id": 5,
  "tool_name": "CARBIDE DRILL",
  "holder_name": "ER32 100GPL",
  "tool_life_threshold": 3000,
  "supervisor_email": "supervisor@company.com"
}
```

### 2. Record Tool Usage

**Process 1: AMS-141 Column**
```bash
POST /api/tool-life/usage/record
{
  "tool_id": 5,
  "component_id": "AMS-141",
  "no_of_holes": 43,
  "cutting_length": 23
}

Response:
{
  "usage_score": 989,
  "cumulative_total": 989,
  "tool_life_threshold": 3000,
  "usage_percentage": "32.97",
  "remaining_life": 2011,
  "alert_type": "NONE",
  "status": "ACTIVE"
}
```

**Process 2: AMS-915 Column (Same Tool)**
```bash
POST /api/tool-life/usage/record
{
  "tool_id": 5,
  "component_id": "AMS-915",
  "no_of_holes": 50,
  "cutting_length": 15
}

Response:
{
  "usage_score": 750,
  "cumulative_total": 1739,
  "tool_life_threshold": 3000,
  "usage_percentage": "57.97",
  "remaining_life": 1261,
  "alert_type": "NONE",
  "status": "ACTIVE"
}
```

**Process 3: AMS-103 Column (Reaches 90% - WARNING)**
```bash
POST /api/tool-life/usage/record
{
  "tool_id": 5,
  "component_id": "AMS-103",
  "no_of_holes": 42,
  "cutting_length": 30
}

Response:
{
  "usage_score": 1260,
  "cumulative_total": 2999,
  "tool_life_threshold": 3000,
  "usage_percentage": "99.97",
  "remaining_life": 1,
  "alert_type": "WARNING",
  "status": "NEAR_END_OF_LIFE",
  "recommendation": "Tool nearing end of life, prepare for replacement"
}

Alert Created:
{
  "alert_type": "WARNING",
  "alert_message": "CAUTION: Tool ID 5 (CARBIDE DRILL) is nearing its tool life limit. Current usage: 2999/3000 (99.97%). Remaining usage: 1 unit. Please prepare for tool maintenance/replacement. Components affected: AMS-141, AMS-915, AMS-103"
}
```

**Process 4: AMS-477 Base (Reaches 100% - CRITICAL)**
```bash
POST /api/tool-life/usage/record
{
  "tool_id": 5,
  "component_id": "AMS-477",
  "no_of_holes": 1,
  "cutting_length": 5
}

Response:
{
  "usage_score": 5,
  "cumulative_total": 3004,
  "tool_life_threshold": 3000,
  "usage_percentage": "100.13",
  "remaining_life": 0,
  "alert_type": "CRITICAL",
  "status": "END_OF_LIFE",
  "recommendation": "Tool requires immediate replacement"
}

Alert Created:
{
  "alert_type": "CRITICAL",
  "alert_message": "ALERT: Tool ID 5 (CARBIDE DRILL) has reached its tool life limit of 3000. Cumulative usage: 3004 (100.13%). Immediate maintenance/replacement required. Components affected: AMS-141, AMS-915, AMS-103, AMS-477"
}
```

### 3. Reset Tool After Maintenance

```bash
POST /api/tool-life/5/reset
{
  "maintenance_notes": "Tool replaced with new one",
  "technician_id": "TECH001"
}

Response:
{
  "cumulative_usage_reset": true,
  "new_cumulative_total": 0,
  "previous_total": 3004,
  "status": "ACTIVE"
}
```

## Key Features

### Dual Notification System

1. **WARNING Alert (90% threshold)**
   - Triggered when cumulative usage ≥ 90% of tool life
   - Allows supervisor to prepare for maintenance
   - Tool continues to be usable
   - Status: NEAR_END_OF_LIFE

2. **CRITICAL Alert (100% threshold)**
   - Triggered when cumulative usage ≥ 100% of tool life
   - Immediate action required
   - Status: END_OF_LIFE

### No Duplicate Alerts

- System checks for existing alerts before creating new ones
- Only one WARNING alert per tool
- Only one CRITICAL alert per tool
- Prevents notification spam

### Cumulative Tracking

- Usage accumulates across all components
- Formula: `usage_score = no_of_holes × cutting_length`
- Cumulative total persists until manual reset
- Tracks which components used the tool

### Visual Indicators (Flutter)

- Progress bars showing usage percentage
- Color coding:
  - Green: < 90% (ACTIVE)
  - Orange: 90-99% (NEAR_END_OF_LIFE)
  - Red: ≥ 100% (END_OF_LIFE)

## Integration Steps

### 1. Backend Setup

```bash
cd trackpro/backend
npm install
```

The routes are already registered in `server.js`:
```javascript
const toolLifeRoutes = require('./routes/toolLifeTracking');
app.use('/api/tool-life', toolLifeRoutes);
```

### 2. Flutter Setup

Add routes to your Flutter app's main.dart or router:

```dart
'/tool-life-dashboard': (context) => ToolLifeDashboardScreen(),
'/tool-usage-entry': (context) => ToolUsageEntryScreen(),
'/tool-alerts': (context) => ToolAlertsScreen(),
'/tool-life-history': (context) => ToolLifeHistoryScreen(
  toolId: ModalRoute.of(context)!.settings.arguments as int,
),
```

### 3. Email Notification Setup (Optional)

Update the `sendSupervisorNotification` function in `routes/toolLifeTracking.js`:

```javascript
const nodemailer = require('nodemailer');

async function sendSupervisorNotification(email, data) {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASSWORD
    }
  });

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: `Tool Alert: ${data.alert_type} - Tool ID ${data.tool_id}`,
    html: `
      <h2>${data.alert_type} Alert</h2>
      <p><strong>Tool:</strong> ${data.tool_name} (ID: ${data.tool_id})</p>
      <p><strong>Current Usage:</strong> ${data.cumulative_usage}/${data.threshold} (${data.usage_percentage}%)</p>
      <p><strong>Remaining Life:</strong> ${data.remaining_life} units</p>
      <p><strong>Components Affected:</strong> ${data.components.join(', ')}</p>
    `
  };

  await transporter.sendMail(mailOptions);
}
```

## Testing

### 1. Create Test Tool

```bash
curl -X POST http://localhost:3000/api/tool-life/master/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "tool_id": 5,
    "tool_name": "CARBIDE DRILL",
    "holder_name": "ER32 100GPL",
    "tool_life_threshold": 3000,
    "supervisor_email": "supervisor@company.com"
  }'
```

### 2. Record Usage

```bash
curl -X POST http://localhost:3000/api/tool-life/usage/record \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "tool_id": 5,
    "component_id": "AMS-141",
    "no_of_holes": 43,
    "cutting_length": 23
  }'
```

### 3. Check Status

```bash
curl http://localhost:3000/api/tool-life/5/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. View Alerts

```bash
curl http://localhost:3000/api/tool-life/alerts/active \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Database Collections

### master_tools
```javascript
{
  _id: ObjectId,
  tool_id: 5,
  tool_name: "CARBIDE DRILL",
  holder_name: "ER32 100GPL",
  tool_life_threshold: 3000,
  status: "ACTIVE",
  supervisor_email: "supervisor@company.com",
  created_date: ISODate
}
```

### tool_usage_logs
```javascript
{
  _id: ObjectId,
  tool_id: 5,
  component_id: "AMS-141",
  no_of_holes: 43,
  cutting_length: 23,
  usage_score: 989,
  cumulative_total_before: 0,
  cumulative_total_after: 989,
  tool_life_threshold: 3000,
  usage_percentage: 32.97,
  remaining_life: 2011,
  alert_type: "NONE",
  timestamp: ISODate
}
```

### tool_alerts
```javascript
{
  _id: ObjectId,
  tool_id: 5,
  tool_name: "CARBIDE DRILL",
  alert_type: "CRITICAL",
  cumulative_usage: 3004,
  usage_percentage: 100.13,
  components_used: ["AMS-141", "AMS-915", "AMS-103", "AMS-477"],
  alert_status: "SENT",
  alert_message: "ALERT: Tool ID 5...",
  created_date: ISODate,
  sent_date: ISODate
}
```

## Troubleshooting

### Issue: Alerts not being sent

**Solution:** Check that supervisor_email is set in master tool:
```bash
db.mastertools.updateOne(
  { tool_id: 5 },
  { $set: { supervisor_email: "supervisor@company.com" } }
)
```

### Issue: Cumulative total not persisting

**Solution:** Verify the latest log entry:
```bash
db.toolusagelogs.find({ tool_id: 5 }).sort({ timestamp: -1 }).limit(1)
```

### Issue: Duplicate alerts

**Solution:** System prevents duplicates automatically. Check alert status:
```bash
db.toolalerts.find({ tool_id: 5, alert_status: { $in: ["PENDING", "SENT"] } })
```

## Future Enhancements

1. **Real-time Notifications**
   - Integrate Socket.io for live dashboard updates
   - Push notifications via Firebase Cloud Messaging

2. **Analytics Dashboard**
   - Tool usage trends
   - Predictive maintenance scheduling
   - Component-wise usage breakdown

3. **Batch Operations**
   - Import multiple tools from CSV
   - Bulk reset after maintenance

4. **Advanced Alerts**
   - SMS notifications
   - Slack/Teams integration
   - Escalation rules

## Support

For issues or questions, contact the development team or refer to the main TrackPro documentation.
