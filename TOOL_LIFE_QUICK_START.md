# Tool Life Tracking - Quick Start Guide

## 🚀 Quick Setup (5 Minutes)

### Step 1: Run Setup Script

```bash
cd trackpro/backend
node scripts/setup-tool-life-tracking.js
```

This creates 3 sample tools:
- Tool ID 5: CARBIDE DRILL (Threshold: 3000)
- Tool ID 10: END MILL (Threshold: 5000)
- Tool ID 15: FACE MILL (Threshold: 10000)

### Step 2: Start Backend Server

```bash
cd trackpro/backend
npm start
```

Server runs on: `http://localhost:3000`

### Step 3: Test API (Using Postman or curl)

#### Record Tool Usage

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

#### Check Tool Status

```bash
curl http://localhost:3000/api/tool-life/5/status \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 4: Run Flutter App

```bash
cd trackpro/trackpro
flutter run
```

Navigate to Tool Life Dashboard to see visual progress bars.

## 📱 Flutter Screens

### 1. Tool Life Dashboard
- **Route:** `/tool-life-dashboard`
- **Shows:** All tools with progress bars, usage percentage, status
- **Actions:** View history, record usage, check alerts

### 2. Tool Usage Entry
- **Route:** `/tool-usage-entry`
- **Purpose:** Record tool usage for a component
- **Inputs:** Component, Tool ID, Holes, Cutting Length
- **Output:** Usage score, cumulative total, alerts

### 3. Tool Alerts
- **Route:** `/tool-alerts`
- **Shows:** Active WARNING and CRITICAL alerts
- **Features:** Color-coded by severity, component tracking

### 4. Tool History
- **Route:** `/tool-life-history`
- **Shows:** Complete usage history for a tool
- **Features:** Component breakdown, alert highlights

## 🎯 Real-World Example

### Scenario: CARBIDE DRILL (Tool ID 5, Threshold: 3000)

**Process 1: AMS-141 Column**
```json
Input: { "no_of_holes": 43, "cutting_length": 23 }
Calculation: 43 × 23 = 989
Cumulative: 989
Status: ✓ ACTIVE (32.97%)
Alert: NO
```

**Process 2: AMS-915 Column**
```json
Input: { "no_of_holes": 50, "cutting_length": 15 }
Calculation: 50 × 15 = 750
Cumulative: 989 + 750 = 1739
Status: ✓ ACTIVE (57.97%)
Alert: NO
```

**Process 3: AMS-103 Column**
```json
Input: { "no_of_holes": 42, "cutting_length": 30 }
Calculation: 42 × 30 = 1260
Cumulative: 1739 + 1260 = 2999
Status: ⚠ NEAR_END_OF_LIFE (99.97%)
Alert: ✓ WARNING - Prepare for maintenance
```

**Process 4: AMS-477 Base**
```json
Input: { "no_of_holes": 1, "cutting_length": 5 }
Calculation: 1 × 5 = 5
Cumulative: 2999 + 5 = 3004
Status: 🚨 END_OF_LIFE (100.13%)
Alert: ✓ CRITICAL - Immediate replacement required
```

## 🔔 Alert System

### WARNING Alert (90% Threshold)
- **Trigger:** Usage ≥ 90% of tool life
- **Purpose:** Prepare for maintenance
- **Action:** Schedule replacement
- **Tool Status:** NEAR_END_OF_LIFE
- **Color:** Orange

### CRITICAL Alert (100% Threshold)
- **Trigger:** Usage ≥ 100% of tool life
- **Purpose:** Immediate action required
- **Action:** Replace tool immediately
- **Tool Status:** END_OF_LIFE
- **Color:** Red

## 🔧 Common Operations

### Create New Master Tool

```bash
POST /api/tool-life/master/create
{
  "tool_id": 20,
  "tool_name": "BORING BAR",
  "holder_name": "BT40 150GPL",
  "tool_life_threshold": 8000,
  "supervisor_email": "supervisor@company.com"
}
```

### Reset Tool After Maintenance

```bash
POST /api/tool-life/5/reset
{
  "maintenance_notes": "Tool replaced with new one",
  "technician_id": "TECH001"
}
```

### Get All Master Tools

```bash
GET /api/tool-life/master/all
```

### Get Tool History

```bash
GET /api/tool-life/5/history
```

### Get Active Alerts

```bash
GET /api/tool-life/alerts/active
```

## 📊 Dashboard Features

### Visual Indicators

**Progress Bar Colors:**
- 🟢 Green: 0-89% (ACTIVE)
- 🟠 Orange: 90-99% (NEAR_END_OF_LIFE)
- 🔴 Red: 100%+ (END_OF_LIFE)

**Status Badges:**
- ACTIVE: Tool operating normally
- NEAR_END_OF_LIFE: Prepare for replacement
- END_OF_LIFE: Immediate replacement required

### Real-time Updates

- Refresh button to reload data
- Pull-to-refresh on mobile
- Auto-update every 30 seconds (optional)

## 🎨 Customization

### Add More Components

Edit `tool_usage_entry_screen.dart`:

```dart
final List<String> _components = [
  'AMS-141',
  'AMS-915',
  'AMS-103',
  'AMS-477',
  'AMS-500',  // Add new component
  'AMS-600',  // Add new component
];
```

### Change Alert Thresholds

Edit `toolLifeTracking.js`:

```javascript
const warningThreshold = toolLifeThreshold * 0.85; // Change to 85%
```

### Customize Email Notifications

Update `sendSupervisorNotification` function with your email service.

## 🐛 Troubleshooting

### Issue: "Tool not found in master list"
**Solution:** Create the tool first using `/master/create` endpoint

### Issue: Cumulative total not updating
**Solution:** Check that tool_id matches exactly in master tools

### Issue: No alerts being sent
**Solution:** Verify supervisor_email is set in master tool

### Issue: Flutter screens not showing data
**Solution:** Check API base URL in `api_client.dart`

## 📝 API Authentication

All endpoints require authentication. Include token in header:

```bash
Authorization: Bearer YOUR_JWT_TOKEN
```

Get token from login endpoint:
```bash
POST /api/auth/login
{
  "username": "your_username",
  "password": "your_password"
}
```

## 🎓 Next Steps

1. ✅ Set up sample tools (Done with setup script)
2. ✅ Test API endpoints
3. ✅ Launch Flutter app
4. ⬜ Configure email notifications
5. ⬜ Add your actual tools
6. ⬜ Train operators on usage entry
7. ⬜ Set up supervisor alerts

## 📚 Additional Resources

- Full Documentation: `TOOL_LIFE_TRACKING_GUIDE.md`
- API Reference: See guide for all endpoints
- Flutter Widgets: Check screen files for customization

## 💡 Tips

1. **Start with test data** - Use sample tools to understand the system
2. **Monitor alerts** - Check alerts screen regularly
3. **Reset after maintenance** - Always reset cumulative total after tool replacement
4. **Track components** - System automatically tracks which components used each tool
5. **Use history** - Review history to optimize tool life thresholds

## 🆘 Support

For issues or questions:
1. Check `TOOL_LIFE_TRACKING_GUIDE.md` for detailed documentation
2. Review API responses for error messages
3. Check backend logs for debugging
4. Verify MongoDB collections are created

---

**Ready to track tool life? Start with Step 1! 🚀**
