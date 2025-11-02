const express = require('express');
const { body, validationResult } = require('express-validator');
const Finishing = require('../models/Finishing');
const { auth } = require('../middleware/auth');
const {
  notifySupervisorOfFinishingStatus,
  notifyAdminOfPauseWithRemark
} = require('../services/notificationService');

const router = express.Router();

// Create new finishing record
router.post('/', auth, [
  body('toolUsed').isIn(['AMS-141 COLUMN', 'AMS-915 COLUMN', 'AMS-103 COLUMN', 'AMS-477 BASE']).withMessage('Invalid tool'),
  body('toolStatus').isIn(['Working', 'Faulty']).withMessage('Invalid tool status'),
  body('partComponentId').notEmpty().withMessage('Part/Component ID is required'),
  body('operatorName').notEmpty().withMessage('Operator name is required'),
  body('remarks').optional().isString(),
  body('duration').optional().isString(),
  body('isCompleted').optional().isBoolean()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const finishingData = {
      toolUsed: req.body.toolUsed,
      toolStatus: req.body.toolStatus,
      partComponentId: req.body.partComponentId,
      operatorName: req.body.operatorName,
      remarks: req.body.remarks,
      duration: req.body.duration,
      isCompleted: req.body.isCompleted === 'true' || req.body.isCompleted === true,
      processedBy: req.user._id
    };

    const finishing = new Finishing(finishingData);
    await finishing.save();
    await finishing.populate('processedBy', 'name username');

    // Send notification to supervisors about process start
    try {
      await notifySupervisorOfFinishingStatus(
        finishing.partComponentId,
        'Started',
        finishing.operatorName,
        finishing.createdAt
      );
    } catch (notificationError) {
      console.error('Failed to send finishing start notification:', notificationError);
      // Don't fail the creation if notification fails
    }

    res.status(201).json(finishing);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get all finishing records
router.get('/', auth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const [finishingRecords, total] = await Promise.all([
      Finishing.find()
        .populate('processedBy', 'name username')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean(),
      Finishing.countDocuments()
    ]);

    res.json({
      finishingRecords,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      total
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get finishing record by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const finishing = await Finishing.findById(req.params.id)
      .populate('processedBy', 'name username');

    if (!finishing) {
      return res.status(404).json({ message: 'Finishing record not found' });
    }

    res.json(finishing);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update finishing record
router.put('/:id', auth, [
  body('toolUsed').optional().isIn(['AMS-141 COLUMN', 'AMS-915 COLUMN', 'AMS-103 COLUMN', 'AMS-477 BASE']).withMessage('Invalid tool'),
  body('toolStatus').optional().isIn(['Working', 'Faulty']).withMessage('Invalid tool status'),
  body('partComponentId').optional().notEmpty().withMessage('Part/Component ID cannot be empty'),
  body('operatorName').optional().notEmpty().withMessage('Operator name cannot be empty'),
  body('remarks').optional().isString(),
  body('duration').optional().isString(),
  body('totalDurationSeconds').optional().isNumeric(),
  body('workingDurationSeconds').optional().isNumeric(),
  body('totalPauseDurationSeconds').optional().isNumeric(),
  body('pauseCount').optional().isNumeric(),
  body('pauses').optional().isArray(),
  body('status').optional().isIn(['in_progress', 'completed']),
  body('isCompleted').optional().isBoolean()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const updateData = { ...req.body };
    if (req.body.isCompleted !== undefined) {
      updateData.isCompleted = req.body.isCompleted === 'true' || req.body.isCompleted === true;
    }
    
    // If status is completed, set isCompleted to true
    if (req.body.status === 'completed') {
      updateData.isCompleted = true;
    }

    // Get the current finishing record before update to detect changes
    const currentFinishing = await Finishing.findById(req.params.id);
    if (!currentFinishing) {
      return res.status(404).json({ message: 'Finishing record not found' });
    }

    const finishing = await Finishing.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    ).populate('processedBy', 'name username');

    if (!finishing) {
      return res.status(404).json({ message: 'Finishing record not found' });
    }

    // Send notifications based on changes
    try {
      // Check for status changes
      if (req.body.status && req.body.status !== currentFinishing.status) {
        if (req.body.status === 'completed') {
          await notifySupervisorOfFinishingStatus(
            finishing.partComponentId,
            'Ended',
            finishing.operatorName,
            new Date()
          );
        }
      }

      // Check for pause with remarks
      if (req.body.pauses && Array.isArray(req.body.pauses)) {
        const newPauses = req.body.pauses;
        const currentPauses = currentFinishing.pauses || [];

        // Find new pauses with remarks
        for (const newPause of newPauses) {
          if (newPause.remarks && newPause.remarks.trim()) {
            // Check if this pause is new or updated
            const existingPause = currentPauses.find(cp =>
              cp.startTime.getTime() === new Date(newPause.startTime).getTime()
            );

            if (!existingPause || existingPause.remarks !== newPause.remarks) {
              // This is a new pause with remark or remark was updated
              await notifyAdminOfPauseWithRemark(
                finishing.partComponentId,
                finishing.operatorName,
                newPause.remarks,
                new Date()
              );
              break; // Only send one notification per update
            }
          }
        }
      }

      // Check if manually marked as completed
      if (req.body.isCompleted === true && currentFinishing.isCompleted !== true) {
        await notifySupervisorOfFinishingStatus(
          finishing.partComponentId,
          'Ended',
          finishing.operatorName,
          new Date()
        );
      }

    } catch (notificationError) {
      console.error('Failed to send finishing update notification:', notificationError);
      // Don't fail the update if notification fails
    }

    res.json(finishing);
  } catch (error) {
    console.error('Update error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Delete finishing record
router.delete('/:id', auth, async (req, res) => {
  try {
    const finishing = await Finishing.findByIdAndDelete(req.params.id);

    if (!finishing) {
      return res.status(404).json({ message: 'Finishing record not found' });
    }

    res.json({ message: 'Finishing record deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get finishing records by user
router.get('/user/:userId', auth, async (req, res) => {
  try {
    const finishingRecords = await Finishing.find({ processedBy: req.params.userId })
      .populate('processedBy', 'name username')
      .sort({ createdAt: -1 });

    res.json(finishingRecords);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get tool usage statistics
router.get('/stats/tools', auth, async (req, res) => {
  try {
    const toolStats = await Finishing.aggregate([
      {
        $group: {
          _id: '$toolUsed',
          count: { $sum: 1 },
          workingCount: {
            $sum: { $cond: [{ $eq: ['$toolStatus', 'Working'] }, 1, 0] }
          },
          faultyCount: {
            $sum: { $cond: [{ $eq: ['$toolStatus', 'Faulty'] }, 1, 0] }
          }
        }
      },
      { $sort: { count: -1 } }
    ]);

    res.json(toolStats);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;