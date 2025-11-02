# Tool Life Tracking System - Verification Checklist

Use this checklist to verify that the Tool Life Tracking System is properly installed and working.

## ✅ Pre-Installation Checklist

### System Requirements
- [ ] Node.js 14+ installed
- [ ] MongoDB 4+ installed and running
- [ ] Flutter 3+ installed
- [ ] Postman installed (for API testing)
- [ ] Git installed

### Verify Installations
```bash
# Check Node.js
node --version  # Should show v14.x or higher

# Check MongoDB
mongod --version  # Should show 4.x or higher

# Check Flutter
flutter --version  # Should show 3.x or higher
```

---

## 📦 Backend Installation Checklist

### 1. File Verification
Navigate to `trackpro/backend/` and verify these files exist:

- [ ] `models/MasterTool.js`
- [ ] `models/ToolUsageLog.js`
- [ ] `models/ToolAlert.js`
- [ ] `routes/toolLifeTracking.js`
- [ ] `scripts/setup-tool-life-tracking.js`
- [ ] `server.js` (updated with tool life routes)

### 2. Dependencies Installation
```bash
cd trackpro/backend
npm install
```

- [ ] No errors during installation
- [ ] `node_modules/` folder created
- [ ] `package-lock.json` updated

### 3. Database Setup
```bash
# Start MongoDB (if not running)
# Windows:
net start MongoDB

# Linux/Mac:
sudo systemctl start mongod
```

- [ ] MongoDB is running
- [ ] Can connect to `mongodb://localhost:27017`

### 4. Run Setup Script
```bash
node scripts/setup-tool-life-tracking.js
```

Expected output:
```
Connecting to MongoDB...
Connected to MongoDB

Creating sample master tools...
✓ Created tool: CARBIDE DRILL (ID: 5)
✓ Created tool: END MILL (ID: 10)
✓ Created tool: FACE MILL (ID: 15)

✓ Tool Life Tracking setup completed successfully!
```

- [ ] Script runs without errors
- [ ] 3 sample tools created
- [ ] Success message displayed

### 5. Start Backend Server
```bash
npm start
```

Expected output:
```
Server running on port 3000
```

- [ ] Server starts without errors
- [ ] Port 3000 is accessible
- [ ] No connection errors

---

## 📱 Flutter Installation Checklist

### 1. File Verification
Navigate to `trackpro/trackpro/lib/` and verify these files exist:

- [ ] `models/tool_life_model.dart`
- [ ] `services/tool_life_service.dart`
- [ ] `screens/tool_life_dashboard_screen.dart`
- [ ] `screens/tool_usage_entry_screen.dart`
- [ ] `screens/tool_alerts_screen.dart`
- [ ] `screens/tool_life_history_screen.dart`

### 2. Install Dependencies
```bash
cd trackpro/trackpro
flutter pub get
flutter pub add intl
```

- [ ] No errors during installation
- [ ] `pubspec.lock` updated
- [ ] `intl` package added

### 3. Verify API Client Configuration
Check `lib/utils/api_client.dart`:

- [ ] Base URL is correct (http://localhost:3000 for development)
- [ ] API client is properly configured

### 4. Run Flutter App
```bash
flutter run
```

- [ ] App builds successfully
- [ ] No compilation errors
- [ ] App launches on device/emulator

---

## 🧪 API Testing Checklist

### 1. Import Postman Collection
- [ ] Open Postman
- [ ] Import `Tool_Life_Tracking_API.postman_collection.json`
- [ ] Collection appears in Postman

### 2. Set Environment Variables
- [ ] Set `base_url` to `http://localhost:3000`
- [ ] Set `token` to your JWT token (get from login)

### 3. Get JWT Token
```bash
POST http://localhost:3000/api/auth/login
{
  "username": "your_username",
  "password": "your_password"
}
```

- [ ] Login successful
- [ ] Token received
- [ ] Token copied to Postman variable

### 4. Test Master Tools Endpoints

#### Get All Master Tools
```bash
GET /api/tool-life/master/all
```

Expected response:
```json
{
  "success": true,
  "data": {
    "masterTools": [
      {
        "tool_id": 5,
        "tool_name": "CARBIDE DRILL",
        "tool_life_threshold": 3000,
        ...
      }
    ]
  }
}
```

- [ ] Request successful (200 OK)
- [ ] 3 tools returned
- [ ] Tool data is correct

#### Create Master Tool
```bash
POST /api/tool-life/master/create
{
  "tool_id": 20,
  "tool_name": "TEST TOOL",
  "tool_life_threshold": 5000
}
```

- [ ] Request successful (201 Created)
- [ ] Tool created in database
- [ ] Tool appears in GET all request

### 5. Test Usage Recording

#### Record Usage - Process 1
```bash
POST /api/tool-life/usage/record
{
  "tool_id": 5,
  "component_id": "AMS-141",
  "no_of_holes": 43,
  "cutting_length": 23
}
```

Expected response:
```json
{
  "success": true,
  "data": {
    "usage_score": 989,
    "cumulative_total": 989,
    "usage_percentage": "32.97",
    "alert_type": "NONE",
    "status": "ACTIVE"
  }
}
```

- [ ] Request successful (200 OK)
- [ ] Usage score calculated correctly (43 × 23 = 989)
- [ ] Cumulative total is 989
- [ ] No alert triggered

#### Record Usage - Process 2
```bash
POST /api/tool-life/usage/record
{
  "tool_id": 5,
  "component_id": "AMS-915",
  "no_of_holes": 50,
  "cutting_length": 15
}
```

- [ ] Request successful
- [ ] Usage score = 750
- [ ] Cumulative total = 1739 (989 + 750)
- [ ] No alert triggered

#### Record Usage - Process 3 (WARNING)
```bash
POST /api/tool-life/usage/record
{
  "tool_id": 5,
  "component_id": "AMS-103",
  "no_of_holes": 42,
  "cutting_length": 30
}
```

- [ ] Request successful
- [ ] Usage score = 1260
- [ ] Cumulative total = 2999 (1739 + 1260)
- [ ] WARNING alert triggered
- [ ] Alert type = "WARNING"
- [ ] Status = "NEAR_END_OF_LIFE"

#### Record Usage - Process 4 (CRITICAL)
```bash
POST /api/tool-life/usage/record
{
  "tool_id": 5,
  "component_id": "AMS-477",
  "no_of_holes": 1,
  "cutting_length": 5
}
```

- [ ] Request successful
- [ ] Usage score = 5
- [ ] Cumulative total = 3004 (2999 + 5)
- [ ] CRITICAL alert triggered
- [ ] Alert type = "CRITICAL"
- [ ] Status = "END_OF_LIFE"

### 6. Test Tool Status
```bash
GET /api/tool-life/5/status
```

- [ ] Request successful
- [ ] Cumulative usage = 3004
- [ ] Usage percentage = 100.13%
- [ ] Remaining life = 0
- [ ] Alert status = "CRITICAL"
- [ ] Components used = ["AMS-141", "AMS-915", "AMS-103", "AMS-477"]

### 7. Test Alerts
```bash
GET /api/tool-life/alerts/active
```

- [ ] Request successful
- [ ] 2 alerts returned (WARNING + CRITICAL)
- [ ] Alert messages are correct
- [ ] Components tracked correctly

### 8. Test Tool History
```bash
GET /api/tool-life/5/history
```

- [ ] Request successful
- [ ] 4 usage logs returned
- [ ] Cumulative progression is correct
- [ ] Alert flags are set correctly

### 9. Test Tool Reset
```bash
POST /api/tool-life/5/reset
{
  "maintenance_notes": "Tool replaced",
  "technician_id": "TECH001"
}
```

- [ ] Request successful
- [ ] Cumulative total reset to 0
- [ ] Status changed to "ACTIVE"
- [ ] Alerts acknowledged

---

## 📱 Flutter App Testing Checklist

### 1. Tool Life Dashboard Screen

Launch app and navigate to Tool Life Dashboard:

- [ ] Screen loads without errors
- [ ] All tools displayed
- [ ] Progress bars visible
- [ ] Colors correct (Green/Orange/Red)
- [ ] Status badges displayed
- [ ] Tool information accurate
- [ ] Refresh button works
- [ ] Pull-to-refresh works

### 2. Tool Usage Entry Screen

Click "Record Usage" on any tool:

- [ ] Screen opens
- [ ] Component dropdown works
- [ ] All 4 components listed (AMS-141, AMS-915, AMS-103, AMS-477)
- [ ] Tool ID field populated (if coming from dashboard)
- [ ] Number input fields work
- [ ] Validation works (empty fields)
- [ ] Submit button works
- [ ] Loading indicator shows during submission
- [ ] Result card displays after submission
- [ ] Alert dialog shows for WARNING/CRITICAL

### 3. Tool Alerts Screen

Click floating action button on dashboard:

- [ ] Screen opens
- [ ] Active alerts displayed
- [ ] Color coding correct (Orange for WARNING, Red for CRITICAL)
- [ ] Alert icons displayed
- [ ] Component list shown
- [ ] Timestamp displayed
- [ ] Tap alert to see details
- [ ] Detail dialog shows full information
- [ ] Refresh button works

### 4. Tool History Screen

Click "History" on any tool:

- [ ] Screen opens
- [ ] Usage logs displayed
- [ ] Chronological order (newest first)
- [ ] Component names shown
- [ ] Usage scores calculated correctly
- [ ] Cumulative progression visible
- [ ] Alert-triggering events highlighted
- [ ] Timestamp formatted correctly
- [ ] Refresh button works

---

## 🔍 Database Verification Checklist

### Connect to MongoDB
```bash
# Using MongoDB Compass or mongo shell
mongo mongodb://localhost:27017/trackpro
```

### 1. Verify Collections Created
```javascript
show collections
```

Expected output:
```
mastertools
toolusagelogs
toolalerts
```

- [ ] `mastertools` collection exists
- [ ] `toolusagelogs` collection exists
- [ ] `toolalerts` collection exists

### 2. Verify Master Tools
```javascript
db.mastertools.find().pretty()
```

- [ ] 3 sample tools exist (IDs: 5, 10, 15)
- [ ] Tool data is complete
- [ ] Thresholds are correct

### 3. Verify Usage Logs
```javascript
db.toolusagelogs.find({ tool_id: 5 }).pretty()
```

- [ ] 4 usage logs exist for tool ID 5
- [ ] Cumulative totals progress correctly
- [ ] Alert flags are set correctly

### 4. Verify Alerts
```javascript
db.toolalerts.find({ tool_id: 5 }).pretty()
```

- [ ] 2 alerts exist (WARNING + CRITICAL)
- [ ] Alert messages are correct
- [ ] Components are tracked
- [ ] Alert status is correct

### 5. Verify Indexes
```javascript
db.mastertools.getIndexes()
db.toolusagelogs.getIndexes()
db.toolalerts.getIndexes()
```

- [ ] Indexes on tool_id exist
- [ ] Indexes on timestamp exist
- [ ] Compound indexes exist

---

## 🎯 Functional Testing Checklist

### Scenario 1: New Tool Creation
1. [ ] Create new master tool via API
2. [ ] Tool appears in Flutter dashboard
3. [ ] Tool status is ACTIVE
4. [ ] Cumulative usage is 0

### Scenario 2: Normal Usage (< 90%)
1. [ ] Record usage below 90% threshold
2. [ ] Usage score calculated correctly
3. [ ] Cumulative total updates
4. [ ] No alert triggered
5. [ ] Status remains ACTIVE
6. [ ] Progress bar updates in Flutter

### Scenario 3: WARNING Alert (90-99%)
1. [ ] Record usage reaching 90% threshold
2. [ ] WARNING alert created
3. [ ] Alert appears in alerts screen
4. [ ] Status changes to NEAR_END_OF_LIFE
5. [ ] Progress bar turns orange
6. [ ] Alert message is correct

### Scenario 4: CRITICAL Alert (≥100%)
1. [ ] Record usage reaching 100% threshold
2. [ ] CRITICAL alert created
3. [ ] Alert appears in alerts screen
4. [ ] Status changes to END_OF_LIFE
5. [ ] Progress bar turns red
6. [ ] Alert message is correct

### Scenario 5: Tool Reset
1. [ ] Reset tool via API
2. [ ] Cumulative total becomes 0
3. [ ] Status changes to ACTIVE
4. [ ] Alerts are acknowledged
5. [ ] Progress bar resets in Flutter
6. [ ] Can record new usage

### Scenario 6: Multiple Components
1. [ ] Record usage on AMS-141
2. [ ] Record usage on AMS-915 (same tool)
3. [ ] Cumulative total accumulates
4. [ ] Both components tracked
5. [ ] History shows both entries

---

## 🐛 Error Handling Checklist

### API Error Handling
- [ ] Invalid tool_id returns 404
- [ ] Missing required fields returns 400
- [ ] Invalid token returns 401
- [ ] Supervisor-only endpoints protected
- [ ] Duplicate tool creation prevented

### Flutter Error Handling
- [ ] Network errors handled gracefully
- [ ] Loading states displayed
- [ ] Error messages shown to user
- [ ] Retry functionality works
- [ ] Empty states handled

---

## 📊 Performance Checklist

### API Performance
- [ ] Response time < 100ms for status check
- [ ] Response time < 200ms for usage recording
- [ ] Database queries optimized
- [ ] No N+1 query problems

### Flutter Performance
- [ ] Dashboard loads in < 2 seconds
- [ ] Smooth scrolling
- [ ] No UI freezing
- [ ] Efficient state management

---

## 🔐 Security Checklist

### Authentication
- [ ] JWT token required for all endpoints
- [ ] Invalid token rejected
- [ ] Expired token rejected
- [ ] Token includes user information

### Authorization
- [ ] Supervisor-only endpoints protected
- [ ] Regular users cannot reset tools
- [ ] Regular users cannot create master tools
- [ ] Users can only see their own data (if applicable)

### Input Validation
- [ ] SQL injection prevented
- [ ] XSS attacks prevented
- [ ] Input sanitization working
- [ ] Type validation working

---

## 📝 Documentation Checklist

### Files Present
- [ ] `TOOL_LIFE_README.md`
- [ ] `TOOL_LIFE_QUICK_START.md`
- [ ] `TOOL_LIFE_TRACKING_GUIDE.md`
- [ ] `SYSTEM_ARCHITECTURE.md`
- [ ] `IMPLEMENTATION_SUMMARY.md`
- [ ] `DEPENDENCIES_NOTE.md`
- [ ] `VERIFICATION_CHECKLIST.md` (this file)
- [ ] `Tool_Life_Tracking_API.postman_collection.json`

### Documentation Quality
- [ ] All endpoints documented
- [ ] Examples provided
- [ ] Screenshots included (or placeholders)
- [ ] Troubleshooting section complete
- [ ] Quick start guide works

---

## ✅ Final Verification

### System Status
- [ ] Backend running without errors
- [ ] Flutter app running without errors
- [ ] Database connected and populated
- [ ] All API endpoints working
- [ ] All Flutter screens working

### Feature Completeness
- [ ] Accumulative tracking works
- [ ] Dual alert system works
- [ ] No duplicate alerts
- [ ] Visual dashboard works
- [ ] Component tracking works
- [ ] Usage history works
- [ ] Reset functionality works

### Ready for Production?
- [ ] All tests passing
- [ ] No critical bugs
- [ ] Documentation complete
- [ ] Performance acceptable
- [ ] Security measures in place

---

## 🎉 Success Criteria

If all items above are checked, the Tool Life Tracking System is:
- ✅ **Properly Installed**
- ✅ **Fully Functional**
- ✅ **Ready for Use**

---

## 📞 Support

If any checklist item fails:
1. Check the error message
2. Review relevant documentation
3. Check backend logs
4. Verify database state
5. Test with Postman
6. Review code changes

---

**Congratulations! Your Tool Life Tracking System is ready! 🚀**
