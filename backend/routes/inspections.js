const express = require('express');
const { body, validationResult } = require('express-validator');
const Inspection = require('../models/Inspection');
const { auth } = require('../middleware/auth');
const upload = require('../middleware/upload');
const { notifySupervisorOfInspectionStart } = require('../services/notificationService');

const router = express.Router();

// Create new inspection
router.post('/', auth, upload.single('image'), [
  body('unitNumber').isNumeric().withMessage('Unit number must be numeric'),
  body('componentName').notEmpty().withMessage('Component name is required'),
  body('supplierDetails').optional().isString(),
  body('remarks').optional().isString(),
  body('duration').optional().isString(),
  body('isCompleted').optional().isBoolean(),
  body('timerEvents').optional().isArray()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const inspectionData = {
      unitNumber: parseInt(req.body.unitNumber),
      componentName: req.body.componentName,
      supplierDetails: req.body.supplierDetails,
      remarks: req.body.remarks,
      duration: req.body.duration,
      isCompleted: req.body.isCompleted === 'true',
      inspectedBy: req.user._id
    };

    // Handle timerEvents if provided
    if (req.body.timerEvents) {
      try {
        inspectionData.timerEvents = typeof req.body.timerEvents === 'string' 
          ? JSON.parse(req.body.timerEvents) 
          : req.body.timerEvents;
      } catch (e) {
        inspectionData.timerEvents = [];
      }
    }

    if (req.file) {
      inspectionData.imagePath = req.file.path;
    }

    if (req.body.isCompleted === 'true') {
      inspectionData.endTime = new Date();
    }

    const inspection = new Inspection(inspectionData);
    await inspection.save();
    await inspection.populate('inspectedBy', 'name username');

    // Send notification to supervisors about inspection start
    try {
      await notifySupervisorOfInspectionStart(
        inspection.componentName,
        inspection.inspectedBy.name,
        inspection.createdAt
      );
    } catch (notificationError) {
      console.error('Failed to send inspection start notification:', notificationError);
      // Don't fail the creation if notification fails
    }

    res.status(201).json(inspection);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get all inspections
router.get('/', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const inspections = await Inspection.find()
      .populate('inspectedBy', 'name username')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Inspection.countDocuments();

    res.json({
      inspections,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      total
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get inspection by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const inspection = await Inspection.findById(req.params.id)
      .populate('inspectedBy', 'name username');

    if (!inspection) {
      return res.status(404).json({ message: 'Inspection not found' });
    }

    res.json(inspection);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update inspection
router.put('/:id', auth, upload.single('image'), [
  body('componentName').optional().notEmpty().withMessage('Component name cannot be empty'),
  body('supplierDetails').optional().isString(),
  body('remarks').optional().isString(),
  body('duration').optional().isString(),
  body('isCompleted').optional().isBoolean()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const updateData = { ...req.body };

    if (req.file) {
      updateData.imagePath = req.file.path;
    }

    if (req.body.isCompleted === 'true' && !updateData.endTime) {
      updateData.endTime = new Date();
    }

    const inspection = await Inspection.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    ).populate('inspectedBy', 'name username');

    if (!inspection) {
      return res.status(404).json({ message: 'Inspection not found' });
    }

    res.json(inspection);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete inspection
router.delete('/:id', auth, async (req, res) => {
  try {
    const inspection = await Inspection.findByIdAndDelete(req.params.id);

    if (!inspection) {
      return res.status(404).json({ message: 'Inspection not found' });
    }

    res.json({ message: 'Inspection deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get inspections by user
router.get('/user/:userId', auth, async (req, res) => {
  try {
    const inspections = await Inspection.find({ inspectedBy: req.params.userId })
      .populate('inspectedBy', 'name username')
      .sort({ createdAt: -1 });

    res.json(inspections);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;