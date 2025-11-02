const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const { notifySupervisorOfNewUser } = require('../services/notificationService');
const mongoose = require('mongoose');

const router = express.Router();

// Get current user profile
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    console.error('Error getting user profile:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Login
router.post('/login', [
  body('username').notEmpty().withMessage('Username is required'),
  body('password').notEmpty().withMessage('Password is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, password } = req.body;
    console.log('Login attempt:', { username });

    // Sanitize username to prevent NoSQL injection
    if (typeof username !== 'string' || typeof password !== 'string') {
      return res.status(400).json({ message: 'Invalid input' });
    }

    // Find user by username
    const user = await User.findOne({ username: username.trim() });
    
    console.log('User found:', user ? 'Yes' : 'No');
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    console.log('Password match:', isMatch);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({ message: 'Account is deactivated' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE }
    );

    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        username: user.username,
        role: user.role,
        assignedTask: user.assignedTask
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Register (Admin only)
router.post('/register', [
  body('name').notEmpty().withMessage('Name is required'),
  body('username').notEmpty().withMessage('Username is required'),
  body('password').isLength({ min: 4 }).withMessage('Password must be at least 4 characters'),
  body('role').isIn(['Admin', 'Supervisor', 'User']).withMessage('Invalid role')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, username, password, role } = req.body;

    // Sanitize inputs to prevent NoSQL injection
    if (typeof username !== 'string' || typeof password !== 'string') {
      return res.status(400).json({ message: 'Invalid input' });
    }

    // Check if user already exists
    const existingUser = await User.findOne({
      username: username.trim()
    });

    if (existingUser) {
      return res.status(400).json({
        message: 'Username already exists'
      });
    }

    // Create new user
    const user = new User({
      name,
      username,
      password,
      role
    });

    await user.save();

    // Send notification to supervisors about new user creation
    try {
      await notifySupervisorOfNewUser({
        name: user.name,
        role: user.role,
        createdAt: user.createdAt
      });
    } catch (notificationError) {
      console.error('Failed to send supervisor notification:', notificationError);
      // Don't fail the registration if notification fails
    }

    res.status(201).json({
      message: 'User created successfully',
      user: {
        id: user._id,
        name: user.name,
        username: user.username,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Register FCM token for push notifications
router.post('/fcm-token', auth, [
  body('token').notEmpty().withMessage('FCM token is required'),
  body('deviceId').notEmpty().withMessage('Device ID is required'),
  body('deviceType').optional().isIn(['android', 'ios', 'web']).withMessage('Invalid device type')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { token, deviceId, deviceType = 'android' } = req.body;
    const userId = req.user.userId;

    // Check if token already exists for this device
    const existingTokenIndex = req.user.fcmTokens.findIndex(t => t.deviceId === deviceId);

    if (existingTokenIndex >= 0) {
      // Update existing token
      req.user.fcmTokens[existingTokenIndex] = {
        token,
        deviceId,
        deviceType,
        lastUsed: new Date()
      };
    } else {
      // Add new token
      req.user.fcmTokens.push({
        token,
        deviceId,
        deviceType,
        lastUsed: new Date()
      });
    }

    await req.user.save();

    res.json({
      message: 'FCM token registered successfully',
      deviceId,
      deviceType
    });

  } catch (error) {
    console.error('Error registering FCM token:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Unregister FCM token
router.delete('/fcm-token/:deviceId', auth, async (req, res) => {
  try {
    const { deviceId } = req.params;
    const userId = req.user.userId;

    // Remove token for this device
    req.user.fcmTokens = req.user.fcmTokens.filter(t => t.deviceId !== deviceId);

    await req.user.save();

    res.json({
      message: 'FCM token unregistered successfully',
      deviceId
    });

  } catch (error) {
    console.error('Error unregistering FCM token:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update push notification preferences
router.put('/push-notifications', auth, [
  body('enabled').isBoolean().withMessage('Enabled must be boolean')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { enabled } = req.body;
    const userId = req.user.userId;

    req.user.pushNotificationsEnabled = enabled;
    await req.user.save();

    res.json({
      message: 'Push notification preferences updated successfully',
      pushNotificationsEnabled: enabled
    });

  } catch (error) {
    console.error('Error updating push notification preferences:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get user's FCM tokens and preferences
router.get('/push-notifications', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('fcmTokens pushNotificationsEnabled');

    res.json({
      pushNotificationsEnabled: user.pushNotificationsEnabled,
      fcmTokens: user.fcmTokens.map(token => ({
        deviceId: token.deviceId,
        deviceType: token.deviceType,
        lastUsed: token.lastUsed
      }))
    });

  } catch (error) {
    console.error('Error getting push notification settings:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;