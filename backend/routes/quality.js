const express = require('express');
const { body, validationResult } = require('express-validator');
const QualityControl = require('../models/QualityControl');
const { auth } = require('../middleware/auth');
const upload = require('../middleware/upload');

const router = express.Router();

// Create new quality control record
router.post('/', auth, upload.single('signatureImage'), [
  body('partId').notEmpty().withMessage('Part ID is required'),
  body('holeDimensions.hole1').isNumeric().withMessage('Hole 1 dimension must be numeric'),
  body('holeDimensions.hole2').isNumeric().withMessage('Hole 2 dimension must be numeric'),
  body('holeDimensions.hole3').isNumeric().withMessage('Hole 3 dimension must be numeric'),
  body('levelReadings.level1').isNumeric().withMessage('Level 1 reading must be numeric'),
  body('levelReadings.level2').isNumeric().withMessage('Level 2 reading must be numeric'),
  body('levelReadings.level3').isNumeric().withMessage('Level 3 reading must be numeric'),
  body('inspectorName').notEmpty().withMessage('Inspector name is required'),
  body('remarks').optional().isString()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const qcData = {
      partId: req.body.partId,
      holeDimensions: req.body.holeDimensions,
      levelReadings: req.body.levelReadings,
      inspectorName: req.body.inspectorName,
      remarks: req.body.remarks,
      inspectedBy: req.user._id
    };

    if (req.file) {
      qcData.signatureImage = req.file.path;
    }

    const qualityControl = new QualityControl(qcData);
    await qualityControl.save();
    await qualityControl.populate('inspectedBy', 'name username');

    res.status(201).json(qualityControl);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get all quality control records
router.get('/', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const [qcRecords, total] = await Promise.all([
      QualityControl.find()
        .populate('inspectedBy', 'name username')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      QualityControl.countDocuments()
    ]);

    res.json({
      qcRecords,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      total
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get quality control record by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const qcRecord = await QualityControl.findById(req.params.id)
      .populate('inspectedBy', 'name username');

    if (!qcRecord) {
      return res.status(404).json({ message: 'Quality control record not found' });
    }

    res.json(qcRecord);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update quality control record
router.put('/:id', auth, upload.single('signatureImage'), [
  body('partId').optional().notEmpty().withMessage('Part ID cannot be empty'),
  body('holeDimensions.hole1').optional().isNumeric().withMessage('Hole 1 dimension must be numeric'),
  body('holeDimensions.hole2').optional().isNumeric().withMessage('Hole 2 dimension must be numeric'),
  body('holeDimensions.hole3').optional().isNumeric().withMessage('Hole 3 dimension must be numeric'),
  body('levelReadings.level1').optional().isNumeric().withMessage('Level 1 reading must be numeric'),
  body('levelReadings.level2').optional().isNumeric().withMessage('Level 2 reading must be numeric'),
  body('levelReadings.level3').optional().isNumeric().withMessage('Level 3 reading must be numeric'),
  body('inspectorName').optional().notEmpty().withMessage('Inspector name cannot be empty'),
  body('remarks').optional().isString()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const updateData = { ...req.body };

    if (req.file) {
      updateData.signatureImage = req.file.path;
    }

    const qcRecord = await QualityControl.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    ).populate('inspectedBy', 'name username');

    if (!qcRecord) {
      return res.status(404).json({ message: 'Quality control record not found' });
    }

    res.json(qcRecord);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete quality control record
router.delete('/:id', auth, async (req, res) => {
  try {
    const qcRecord = await QualityControl.findByIdAndDelete(req.params.id);

    if (!qcRecord) {
      return res.status(404).json({ message: 'Quality control record not found' });
    }

    res.json({ message: 'Quality control record deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get quality control records by user
router.get('/user/:userId', auth, async (req, res) => {
  try {
    const qcRecords = await QualityControl.find({ inspectedBy: req.params.userId })
      .populate('inspectedBy', 'name username')
      .sort({ createdAt: -1 });

    res.json(qcRecords);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get quality statistics
router.get('/stats/quality', auth, async (req, res) => {
  try {
    const statusStats = await QualityControl.aggregate([
      {
        $group: {
          _id: '$qcStatus',
          count: { $sum: 1 }
        }
      }
    ]);

    const totalRecords = statusStats.reduce((sum, item) => sum + item.count, 0);
    const passCount = statusStats.find(s => s._id === 'Pass')?.count || 0;
    const failCount = statusStats.find(s => s._id === 'Fail')?.count || 0;

    const stats = {
      totalRecords,
      passCount,
      failCount,
      toleranceExceededCount: 0,
      passRate: totalRecords > 0 ? ((passCount / totalRecords) * 100).toFixed(2) : 0
    };

    res.json(stats);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get recent failed QC records
router.get('/stats/recent-failures', auth, async (req, res) => {
  try {
    const recentFailures = await QualityControl.find({ qcStatus: 'Fail' })
      .populate('inspectedBy', 'name username')
      .sort({ createdAt: -1 })
      .limit(10);

    res.json(recentFailures);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;