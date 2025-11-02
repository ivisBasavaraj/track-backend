const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth, adminAuth, supervisorAuth } = require('../middleware/auth');
const { notifyUserOfTaskAssignment } = require('../services/notificationService');
const mongoose = require('mongoose');

const router = express.Router();

// Get users for assignment (basic auth only)
router.get('/assign', auth, async (req, res) => {
  try {
    console.log('Fetching users for assignment...');
    const users = await User.find(
      { role: { $in: ['User', 'Supervisor'] } }
    ).select('name username assignedTask').lean();
    
    console.log('Found users:', users.length);
    res.json(users);
  } catch (error) {
    console.error('Error in /assign route:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get all users (Admin and Supervisor)
router.get('/', auth, supervisorAuth, async (req, res) => {
  try {
    const users = await User.find({}).select('-password').lean();
    res.json(users);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get user by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update user role (Admin only)
router.put('/:id/role', auth, adminAuth, [
  body('role').isIn(['Admin', 'Supervisor', 'User']).withMessage('Invalid role')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role: req.body.role },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Assign task to user (Supervisor or Admin)
router.put('/:id/assign-task', auth, supervisorAuth, [
  body('assignedTask').isIn(['Incoming Inspection', 'Finishing', 'Quality Control', 'Delivery']).withMessage('Invalid task')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { assignedTask: req.body.assignedTask },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Send notification to the assigned user
    try {
      const supervisor = await User.findById(req.user.userId);
      await notifyUserOfTaskAssignment(
        user._id,
        req.body.assignedTask,
        supervisor ? supervisor.name : 'Supervisor'
      );
    } catch (notificationError) {
      console.error('Failed to send task assignment notification:', notificationError);
      // Don't fail the assignment if notification fails
    }

    res.json(user);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Unassign task from user (Supervisor or Admin)
router.put('/:id/unassign-task', auth, supervisorAuth, async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { assignedTask: null },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update user status (Admin only)
router.put('/:id/status', auth, adminAuth, [
  body('isActive').isBoolean().withMessage('Status must be boolean')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isActive: req.body.isActive },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update task completion stats
router.put('/:id/stats', auth, [
  body('completedToday').isNumeric().withMessage('Completed today must be a number'),
  body('totalAssigned').isNumeric().withMessage('Total assigned must be a number')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { completedToday, totalAssigned } = req.body;

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { completedToday, totalAssigned },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;