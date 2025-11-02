// Firebase Admin - conditionally loaded
let admin = null;
try {
  admin = require('firebase-admin');
} catch (error) {
  console.log('Firebase Admin not available - push notifications disabled');
}

// Initialize Firebase Admin (configure with your Firebase credentials)
let firebaseInitialized = false;

const initializeFirebase = () => {
  if (firebaseInitialized) return;

  try {
    if (admin && process.env.FIREBASE_SERVICE_ACCOUNT) {
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



// Send push notification to single token
const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!firebaseInitialized) {
    initializeFirebase();
  }

  if (!firebaseInitialized || !fcmToken) {
    return { success: false, error: 'Firebase not configured or no FCM token' };
  }

  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: data,
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        color: '#2196F3',
        channelId: 'trackpro_notifications',
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

// Send push notifications to multiple users
const sendPushToUsers = async (users, title, body, data = {}) => {
  if (!admin) {
    return { success: false, error: 'Firebase Admin not available' };
  }

  if (!firebaseInitialized) {
    initializeFirebase();
  }

  if (!firebaseInitialized) {
    return { success: false, error: 'Firebase not configured' };
  }

  const tokens = [];
  users.forEach(user => {
    if (user.pushNotificationsEnabled && user.fcmTokens && user.fcmTokens.length > 0) {
      user.fcmTokens.forEach(fcmToken => {
        tokens.push(fcmToken.token);
      });
    }
  });

  if (tokens.length === 0) {
    return { success: false, error: 'No FCM tokens found for users' };
  }

  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: data,
    tokens: tokens,
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        color: '#2196F3',
        channelId: 'trackpro_notifications',
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
    const response = await admin.messaging().sendMulticast(message);
    console.log(`Push notifications sent: ${response.successCount}/${tokens.length}`);
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

// 1. Admin User Creation Notification - Notify Supervisor
const notifySupervisorOfNewUser = async (newUserData) => {
  try {
    const User = require('../models/User');
    // Get all supervisors
    const supervisors = await User.find({ role: 'Supervisor', isActive: true });

    if (supervisors.length === 0) {
      console.log('No active supervisors found for notification');
      return { success: false, error: 'No supervisors found' };
    }

    const { name: userName, role: userRole, createdAt } = newUserData;

    // Send push notifications to all supervisors
    const results = [];

    // Send push notifications
    const pushTitle = 'New User Created';
    const pushBody = `A new ${userRole} user "${userName}" has been created.`;
    const pushData = {
      type: 'NEW_USER',
      userName: userName,
      userRole: userRole,
      createdAt: createdAt.toISOString()
    };

    const pushResult = await sendPushToUsers(supervisors, pushTitle, pushBody, pushData);
    results.push({ type: 'push', ...pushResult });

    return { success: true, results };

  } catch (error) {
    console.error('Error sending supervisor notification:', error);
    return { success: false, error: error.message };
  }
};

// 2. Task Assignment Notification - Notify Assigned User
const notifyUserOfTaskAssignment = async (userId, processName, supervisorName) => {
  try {
    const User = require('../models/User');
    const user = await User.findById(userId);

    if (!user) {
      return { success: false, error: 'User not found' };
    }

    // Send push notification
    const results = [];

    // Send push notification
    const pushTitle = 'New Task Assigned';
    const pushBody = `You have been assigned a new task for the process "${processName}".`;
    const pushData = {
      type: 'TASK_ASSIGNED',
      processName: processName,
      assignedBy: supervisorName,
      assignedAt: new Date().toISOString()
    };

    const pushResult = await sendPushToUsers([user], pushTitle, pushBody, pushData);
    results.push({ type: 'push', ...pushResult });

    return { success: true, results };

  } catch (error) {
    console.error('Error sending task assignment notification:', error);
    return { success: false, error: error.message };
  }
};

// 3. Finishing Process Status Notifications - Notify Supervisor
const notifySupervisorOfFinishingStatus = async (processName, status, username, timestamp) => {
  try {
    const User = require('../models/User');
    // Get all supervisors
    const supervisors = await User.find({ role: 'Supervisor', isActive: true });

    if (supervisors.length === 0) {
      console.log('No active supervisors found for notification');
      return { success: false, error: 'No supervisors found' };
    }

    // Send push notifications to all supervisors
    const results = [];

    // Send push notifications
    const pushTitle = `Finishing Process ${status}`;
    const pushBody = `Finishing process "${processName}" has been ${status.toLowerCase()} by ${username}.`;
    const pushData = {
      type: 'FINISHING_STATUS',
      processName: processName,
      status: status,
      updatedBy: username,
      timestamp: new Date(timestamp).toISOString()
    };

    const pushResult = await sendPushToUsers(supervisors, pushTitle, pushBody, pushData);
    results.push({ type: 'push', ...pushResult });

    return { success: true, results };

  } catch (error) {
    console.error('Error sending finishing status notification:', error);
    return { success: false, error: error.message };
  }
};

// 4. Pause with Remark Notification - Notify Admin
const notifyAdminOfPauseWithRemark = async (processName, username, remark, timestamp) => {
  try {
    const User = require('../models/User');
    // Get all admins
    const admins = await User.find({ role: 'Admin', isActive: true });

    if (admins.length === 0) {
      console.log('No active admins found for notification');
      return { success: false, error: 'No admins found' };
    }

    // Send push notifications to all admins
    const results = [];

    // Send push notifications
    const pushTitle = 'ALERT: Process Paused with Remark';
    const pushBody = `Finishing process "${processName}" was paused by ${username} with remark: ${remark.substring(0, 50)}${remark.length > 50 ? '...' : ''}`;
    const pushData = {
      type: 'PAUSE_WITH_REMARK',
      processName: processName,
      pausedBy: username,
      remark: remark,
      timestamp: new Date(timestamp).toISOString()
    };

    const pushResult = await sendPushToUsers(admins, pushTitle, pushBody, pushData);
    results.push({ type: 'push', ...pushResult });

    return { success: true, results };

  } catch (error) {
    console.error('Error sending pause remark notification:', error);
    return { success: false, error: error.message };
  }
};

// 5. Inspection Started Notification - Notify Supervisor
const notifySupervisorOfInspectionStart = async (componentName, username, startTime) => {
  try {
    const User = require('../models/User');
    // Get all supervisors
    const supervisors = await User.find({ role: 'Supervisor', isActive: true });

    if (supervisors.length === 0) {
      console.log('No active supervisors found for notification');
      return { success: false, error: 'No supervisors found' };
    }

    // Send push notifications to all supervisors
    const results = [];

    // Send push notifications
    const pushTitle = 'Inspection Started';
    const pushBody = `Inspection started for "${componentName}" by ${username}.`;
    const pushData = {
      type: 'INSPECTION_STARTED',
      componentName: componentName,
      startedBy: username,
      startTime: new Date(startTime).toISOString()
    };

    const pushResult = await sendPushToUsers(supervisors, pushTitle, pushBody, pushData);
    results.push({ type: 'push', ...pushResult });

    return { success: true, results };

  } catch (error) {
    console.error('Error sending inspection start notification:', error);
    return { success: false, error: error.message };
  }
};

// 6. Tool Management Notifications - Notify Supervisor and Admin
const notifyToolManagementEvent = async (eventType, toolData, recipientRoles = ['Supervisor', 'Admin']) => {
  try {
    const User = require('../models/User');
    // Get recipients based on roles
    const recipients = await User.find({
      role: { $in: recipientRoles },
      isActive: true
    });

    if (recipients.length === 0) {
      console.log('No active recipients found for notification');
      return { success: false, error: 'No recipients found' };
    }

    // Send push notifications to all recipients
    const results = [];

    // Send push notifications
    const pushTitle = `Tool Management: ${eventType}`;
    const pushBody = `A tool management event has occurred: ${eventType}`;
    const pushData = {
      type: 'TOOL_MANAGEMENT',
      eventType: eventType,
      ...toolData,
      timestamp: new Date().toISOString()
    };

    const pushResult = await sendPushToUsers(recipients, pushTitle, pushBody, pushData);
    results.push({ type: 'push', ...pushResult });

    return { success: true, results };

  } catch (error) {
    console.error('Error sending tool management notification:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  initializeFirebase,
  notifySupervisorOfNewUser,
  notifyUserOfTaskAssignment,
  notifySupervisorOfFinishingStatus,
  notifyAdminOfPauseWithRemark,
  notifySupervisorOfInspectionStart,
  notifyToolManagementEvent
};