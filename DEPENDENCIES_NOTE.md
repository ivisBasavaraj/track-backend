# Dependencies for Tool Life Tracking System

## Backend Dependencies

All required dependencies are already included in your existing `package.json`. No additional packages needed!

### Used Dependencies
- ✅ **express** - Web framework
- ✅ **mongoose** - MongoDB ODM
- ✅ **dotenv** - Environment variables
- ✅ **cors** - Cross-origin resource sharing
- ✅ **helmet** - Security headers
- ✅ **express-rate-limit** - Rate limiting

### Optional (For Email Notifications)

If you want to enable email notifications, install:

```bash
npm install nodemailer
```

Then update `routes/toolLifeTracking.js`:

```javascript
const nodemailer = require('nodemailer');

async function sendSupervisorNotification(email, data) {
  const transporter = nodemailer.createTransport({
    service: 'gmail', // or 'smtp.office365.com', etc.
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
      <hr>
      <p style="color: ${data.alert_type === 'CRITICAL' ? 'red' : 'orange'};">
        ${data.alert_type === 'CRITICAL' 
          ? 'Immediate action required - Replace tool immediately' 
          : 'Prepare for tool maintenance/replacement'}
      </p>
    `
  };

  await transporter.sendMail(mailOptions);
  console.log(`Email sent to ${email}`);
}
```

Add to `.env`:
```
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
```

## Flutter Dependencies

### Required (Already in pubspec.yaml)
- ✅ **http** - HTTP requests
- ✅ **flutter/material.dart** - UI framework

### Optional (For Enhanced Features)

Add to `pubspec.yaml` if needed:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  intl: ^0.18.0  # For date formatting (REQUIRED for history screen)
  provider: ^6.0.0  # For state management (optional)
  shared_preferences: ^2.2.0  # For local storage (optional)
  flutter_local_notifications: ^16.0.0  # For local notifications (optional)
  firebase_messaging: ^14.0.0  # For push notifications (optional)
  socket_io_client: ^2.0.0  # For real-time updates (optional)
```

### IMPORTANT: Install intl package

The history and alerts screens use `intl` for date formatting. Install it:

```bash
cd trackpro/trackpro
flutter pub add intl
```

Or manually add to `pubspec.yaml`:
```yaml
dependencies:
  intl: ^0.18.0
```

Then run:
```bash
flutter pub get
```

## MongoDB Setup

No additional setup needed. The system uses your existing MongoDB connection.

### Collections Created Automatically
- `mastertools`
- `toolusagelogs`
- `toolalerts`

### Indexes Created Automatically
All indexes are defined in the models and created on first use.

## Environment Variables

Add to `backend/.env` (if not already present):

```env
# Existing variables
MONGODB_URI=mongodb://localhost:27017/trackpro
PORT=3000
JWT_SECRET=your-secret-key

# Optional: For email notifications
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
```

## API Client Configuration

Update `trackpro/trackpro/lib/utils/api_client.dart` if needed:

```dart
class ApiClient {
  static const String baseUrl = 'http://localhost:3000'; // Change for production
  
  // Rest of your existing code...
}
```

For production:
```dart
static const String baseUrl = 'https://your-production-api.com';
```

## Testing Tools

### Postman
Import the provided collection:
```
Tool_Life_Tracking_API.postman_collection.json
```

### MongoDB Compass
Connect to view collections:
```
mongodb://localhost:27017/trackpro
```

### Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## Quick Dependency Check

### Backend
```bash
cd trackpro/backend
npm list express mongoose dotenv cors helmet express-rate-limit
```

All should show as installed.

### Flutter
```bash
cd trackpro/trackpro
flutter pub deps
```

Should show `http` and `intl` packages.

## Installation Commands

### Fresh Install

**Backend:**
```bash
cd trackpro/backend
npm install
node scripts/setup-tool-life-tracking.js
npm start
```

**Flutter:**
```bash
cd trackpro/trackpro
flutter pub get
flutter pub add intl  # Important!
flutter run
```

## Troubleshooting

### Issue: "intl package not found"
```bash
cd trackpro/trackpro
flutter pub add intl
flutter pub get
```

### Issue: "Cannot connect to MongoDB"
Check MongoDB is running:
```bash
# Windows
net start MongoDB

# Linux/Mac
sudo systemctl start mongod
```

### Issue: "JWT token invalid"
Login again to get fresh token:
```bash
POST /api/auth/login
{
  "username": "your_username",
  "password": "your_password"
}
```

## Production Checklist

- [ ] Update API base URL in Flutter
- [ ] Set production MongoDB URI
- [ ] Configure email service
- [ ] Enable HTTPS
- [ ] Set up proper JWT secret
- [ ] Configure CORS for production domain
- [ ] Set up monitoring/logging
- [ ] Configure backup strategy
- [ ] Test all endpoints
- [ ] Load test the system

## Summary

**Required Actions:**
1. ✅ Backend dependencies - Already installed
2. ⚠️ Flutter `intl` package - **MUST INSTALL**
3. ⬜ Email service - Optional (for notifications)
4. ⬜ Push notifications - Optional (for mobile alerts)

**Minimum to Run:**
```bash
# Backend
cd trackpro/backend
npm start

# Flutter
cd trackpro/trackpro
flutter pub add intl
flutter run
```

That's it! The system is ready to use. 🚀
