const admin = require('firebase-admin');

// Initialize Firebase Admin (configure with your Firebase credentials)
let firebaseInitialized = false;

const initializeFirebase = () => {
  if (firebaseInitialized) return;
  
  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
      firebaseInitialized = true;
      console.log('Firebase Admin initialized successfully');
    } else {
      console.log('Firebase not configured - push notifications disabled');
    }
  } catch (error) {
    console.error('Firebase initialization error:', error.message);
  }
};

const sendPushNotification = async (fcmToken, alertData) => {
  if (!firebaseInitialized) {
    initializeFirebase();
  }
  
  if (!firebaseInitialized || !fcmToken) {
    return { success: false, error: 'Firebase not configured or no FCM token' };
  }

  const { tool_id, tool_name, alert_type, usage_percentage, remaining_life } = alertData;
  const isCritical = alert_type === 'CRITICAL';

  const message = {
    token: fcmToken,
    notification: {
      title: isCritical 
        ? `🚨 CRITICAL: Tool ${tool_id} Replacement Required`
        : `⚠️ WARNING: Tool ${tool_id} Nearing End of Life`,
      body: `${tool_name} - ${usage_percentage.toFixed(1)}% used, ${remaining_life} units remaining`,
    },
    data: {
      type: 'TOOL_LIFE_ALERT',
      tool_id: String(tool_id),
      tool_name: tool_name,
      alert_type: alert_type,
      usage_percentage: String(usage_percentage),
      remaining_life: String(remaining_life),
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        color: isCritical ? '#dc3545' : '#ff9800',
        channelId: 'tool_alerts',
      }
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        }
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Push notification sent:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Push notification error:', error);
    return { success: false, error: error.message };
  }
};

const sendPushToMultipleDevices = async (fcmTokens, alertData) => {
  if (!firebaseInitialized) {
    initializeFirebase();
  }
  
  if (!firebaseInitialized || !fcmTokens || fcmTokens.length === 0) {
    return { success: false, error: 'Firebase not configured or no FCM tokens' };
  }

  const { tool_id, tool_name, alert_type, usage_percentage, remaining_life } = alertData;
  const isCritical = alert_type === 'CRITICAL';

  const message = {
    notification: {
      title: isCritical 
        ? `🚨 CRITICAL: Tool ${tool_id} Replacement Required`
        : `⚠️ WARNING: Tool ${tool_id} Nearing End of Life`,
      body: `${tool_name} - ${usage_percentage.toFixed(1)}% used, ${remaining_life} units remaining`,
    },
    data: {
      type: 'TOOL_LIFE_ALERT',
      tool_id: String(tool_id),
      tool_name: tool_name,
      alert_type: alert_type,
    },
    tokens: fcmTokens,
  };

  try {
    const response = await admin.messaging().sendMulticast(message);
    console.log(`Push notifications sent: ${response.successCount}/${fcmTokens.length}`);
    return { 
      success: true, 
      successCount: response.successCount,
      failureCount: response.failureCount 
    };
  } catch (error) {
    console.error('Push notification error:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  initializeFirebase,
  sendPushNotification,
  sendPushToMultipleDevices
};
