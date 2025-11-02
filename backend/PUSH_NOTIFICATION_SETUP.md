# Push Notification Setup Guide

## Overview
Enable push notifications so supervisors receive tool life alerts even when the app is closed.

## Prerequisites
1. Firebase project
2. Firebase Admin SDK credentials
3. Flutter app configured with Firebase

## Backend Setup

### 1. Install Firebase Admin SDK
```bash
cd backend
npm install firebase-admin
```

### 2. Get Firebase Service Account Key
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create new)
3. Go to Project Settings > Service Accounts
4. Click "Generate New Private Key"
5. Download the JSON file

### 3. Configure Environment Variables
Add to `.env`:
```env
# Firebase Configuration (for Push Notifications)
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"your-project-id",...}
```

**Note**: Paste the entire JSON content as a single line, or use file path:
```env
FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/serviceAccountKey.json
```

## Flutter App Setup

### 1. Add Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
```

### 2. Configure Firebase for Flutter

#### Android Setup
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/google-services.json`
3. Update `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```
4. Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

#### iOS Setup
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in `ios/Runner/GoogleService-Info.plist`
3. Update `ios/Runner/Info.plist` for notification permissions

### 3. Initialize Firebase in Flutter
Update `main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}
```

### 4. Request Notification Permissions
```dart
Future<void> requestNotificationPermissions() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
    
    // Get FCM token
    String? token = await messaging.getToken();
    print('FCM Token: $token');
    
    // Send token to backend
    await ApiService.updateFCMToken(token);
  }
}
```

### 5. Handle Notifications
```dart
void setupPushNotifications() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    // Show local notification
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification clicked: ${message.data}');
    // Navigate to alerts screen
  });
}
```

## Backend API Updates

### Store FCM Token
Add endpoint to store user's FCM token:
```javascript
router.post('/users/fcm-token', auth, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { fcmToken },
      { new: true }
    );
    res.json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});
```

### Update User Model
Add FCM token field to User schema:
```javascript
const userSchema = new mongoose.Schema({
  // ... existing fields
  fcmToken: {
    type: String,
    default: null
  }
});
```

## Testing

### 1. Test Push Notification
```javascript
const { sendPushNotification } = require('./services/pushNotificationService');

sendPushNotification('FCM_TOKEN_HERE', {
  tool_id: 1,
  tool_name: 'TEST TOOL',
  alert_type: 'WARNING',
  usage_percentage: 95,
  remaining_life: 500
});
```

### 2. Test from Backend
```bash
node -e "
const { sendPushNotification } = require('./services/pushNotificationService');
sendPushNotification('YOUR_FCM_TOKEN', {
  tool_id: 1,
  tool_name: 'TEST TOOL',
  alert_type: 'CRITICAL',
  usage_percentage: 100,
  remaining_life: 0
});
"
```

## Notification Flow

1. **Tool usage recorded** → Backend calculates threshold
2. **Threshold reached** → Alert created in database
3. **Get supervisor FCM tokens** → From User model
4. **Send push notification** → Via Firebase Cloud Messaging
5. **User receives notification** → Even if app is closed
6. **User taps notification** → App opens to alerts screen

## Android Notification Channel
Create notification channel for Android:
```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'tool_alerts',
  'Tool Life Alerts',
  description: 'Notifications for tool life warnings and critical alerts',
  importance: Importance.high,
);

await FlutterLocalNotificationsPlugin()
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);
```

## Troubleshooting

### Notifications Not Received
1. Check Firebase configuration
2. Verify FCM token is stored in database
3. Check device notification permissions
4. Verify Firebase service account credentials
5. Check backend logs for errors

### iOS Specific
1. Enable Push Notifications capability in Xcode
2. Configure APNs authentication key in Firebase
3. Test on physical device (not simulator)

## Production Checklist
- [ ] Firebase project created
- [ ] Service account key configured
- [ ] Flutter app configured with Firebase
- [ ] FCM tokens stored in database
- [ ] Notification permissions requested
- [ ] Background handler configured
- [ ] Notification channels created (Android)
- [ ] APNs configured (iOS)
- [ ] Tested on physical devices

## Security Notes
- Never commit Firebase service account key to version control
- Store credentials in environment variables
- Use separate Firebase projects for dev/prod
- Rotate service account keys periodically
- Validate FCM tokens before storing

## Cost
- Firebase Cloud Messaging is FREE
- No limits on number of notifications
- No additional costs for push notifications
