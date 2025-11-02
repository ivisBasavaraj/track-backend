const express = require('express');
const { auth, adminAuth, supervisorAuth } = require('../middleware/auth');
const User = require('../models/User');
const Inspection = require('../models/Inspection');
const Finishing = require('../models/Finishing');
const QualityControl = require('../models/QualityControl');
const Delivery = require('../models/Delivery');

const router = express.Router();

// Get admin dashboard data
router.get('/admin', auth, adminAuth, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get today's statistics
    const todayInspections = await Inspection.countDocuments({
      createdAt: { $gte: today, $lt: tomorrow }
    });

    const todayFinishing = await Finishing.countDocuments({
      createdAt: { $gte: today, $lt: tomorrow }
    });

    const todayQC = await QualityControl.countDocuments({
      createdAt: { $gte: today, $lt: tomorrow }
    });

    const todayDeliveries = await Delivery.countDocuments({
      createdAt: { $gte: today, $lt: tomorrow }
    });

    // Get quality rate
    const totalQC = await QualityControl.countDocuments();
    const passedQC = await QualityControl.countDocuments({ qcStatus: 'Pass' });
    const qualityRate = totalQC > 0 ? ((passedQC / totalQC) * 100).toFixed(1) : 0;

    // Get active users
    const activeUsers = await User.countDocuments({ isActive: true });
    const totalUsers = await User.countDocuments();

    // Get operations status
    const activeInspections = await Inspection.countDocuments({ isCompleted: false });
    const inProgressFinishing = await Finishing.countDocuments({ isCompleted: false });
    const inTransitDeliveries = await Delivery.countDocuments({ deliveryStatus: 'In Transit' });
    const deliveredToday = await Delivery.countDocuments({
      deliveryStatus: 'Delivered',
      actualDeliveryDate: { $gte: today, $lt: tomorrow }
    });

    const operationsStatus = {
      incomingInspection: {
        active: activeInspections,
        completed: todayInspections,
        performance: 85
      },
      finishing: {
        inProgress: inProgressFinishing,
        completed: todayFinishing,
        performance: 73
      },
      qualityControl: {
        inspected: todayQC,
        passRate: qualityRate,
        performance: 98
      },
      delivery: {
        dispatched: todayDeliveries,
        inTransit: inTransitDeliveries,
        delivered: deliveredToday,
        performance: 91
      }
    };

    // Get recent activity
    const recentActivity = [];

    // Recent QC failures
    const recentQCFailures = await QualityControl.find({ qcStatus: 'Fail' })
      .populate('inspectedBy', 'name')
      .sort({ createdAt: -1 })
      .limit(2);

    recentQCFailures.forEach(qc => {
      recentActivity.push({
        type: 'Quality Control Failed',
        description: `Part ID: ${qc.partId} exceeded tolerance`,
        time: qc.createdAt,
        icon: 'error',
        color: 'red'
      });
    });

    // Recent deliveries
    const recentDeliveries = await Delivery.find({ deliveryStatus: 'Delivered' })
      .sort({ actualDeliveryDate: -1 })
      .limit(2);

    recentDeliveries.forEach(delivery => {
      recentActivity.push({
        type: 'Delivery Completed',
        description: `Customer: ${delivery.customerName}`,
        time: delivery.actualDeliveryDate,
        icon: 'check_circle',
        color: 'green'
      });
    });

    // Get active tasks
    const users = await User.find({}, 'totalAssigned');
    const activeTasks = users.reduce((sum, user) => sum + (user.totalAssigned || 0), 0);

    // Sort recent activity by time
    recentActivity.sort((a, b) => new Date(b.time) - new Date(a.time));

    res.json({
      todayOverview: {
        totalUnits: todayInspections + todayFinishing,
        qualityRate: parseFloat(qualityRate),
        activeTasks,
        deliveries: todayDeliveries
      },
      operationsStatus,
      recentActivity: recentActivity.slice(0, 4),
      teamOverview: {
        activeUsers,
        totalUsers,
        efficiency: activeUsers > 0 ? Math.round((activeUsers / totalUsers) * 100) : 0
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get supervisor dashboard data
router.get('/supervisor', auth, supervisorAuth, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get today's statistics for each process
    const todayInspections = await Inspection.countDocuments({
      createdAt: { $gte: today, $lt: tomorrow }
    });

    const todayFinishing = await Finishing.countDocuments({
      createdAt: { $gte: today, $lt: tomorrow }
    });

    const todayQC = await QualityControl.countDocuments({
      createdAt: { $gte: today, $lt: tomorrow }
    });

    const todayDeliveries = await Delivery.countDocuments({
      createdAt: { $gte: today, $lt: tomorrow }
    });

    // Get detailed process statistics
    const inspectionStats = await Inspection.aggregate([
      {
        $match: { createdAt: { $gte: today, $lt: tomorrow } }
      },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          passed: { $sum: { $cond: [{ $eq: ['$status', 'passed'] }, 1, 0] } },
          failed: { $sum: { $cond: [{ $eq: ['$status', 'failed'] }, 1, 0] } },
          avgTime: { $avg: '$processingTime' }
        }
      }
    ]);

    const finishingStats = await Finishing.aggregate([
      {
        $match: { createdAt: { $gte: today, $lt: tomorrow } }
      },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          completed: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
          inProgress: { $sum: { $cond: [{ $eq: ['$status', 'in_progress'] }, 1, 0] } },
          avgTime: { $avg: '$processingTime' }
        }
      }
    ]);

    const qcStats = await QualityControl.aggregate([
      {
        $match: { createdAt: { $gte: today, $lt: tomorrow } }
      },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          passed: { $sum: { $cond: [{ $eq: ['$status', 'passed'] }, 1, 0] } },
          failed: { $sum: { $cond: [{ $eq: ['$status', 'failed'] }, 1, 0] } },
          avgTime: { $avg: '$processingTime' }
        }
      }
    ]);

    const deliveryStats = await Delivery.aggregate([
      {
        $match: { createdAt: { $gte: today, $lt: tomorrow } }
      },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          delivered: { $sum: { $cond: [{ $eq: ['$status', 'delivered'] }, 1, 0] } },
          pending: { $sum: { $cond: [{ $eq: ['$status', 'pending'] }, 1, 0] } },
          avgTime: { $avg: '$processingTime' }
        }
      }
    ]);

    // Get assigned users
    const assignedUsers = await User.find({ assignedTask: { $ne: null } });
    const unassignedUsers = await User.find({ assignedTask: null, role: 'User' });

    // Task distribution
    const taskDistribution = await User.aggregate([
      { $match: { assignedTask: { $ne: null } } },
      { $group: { _id: '$assignedTask', count: { $sum: 1 } } }
    ]);

    // Build detailed process matrix
    const processMatrix = {
      incomingInspection: {
        totalProcessed: todayInspections,
        passed: inspectionStats[0]?.passed || 0,
        failed: inspectionStats[0]?.failed || 0,
        passRate: inspectionStats[0]?.total ? ((inspectionStats[0].passed / inspectionStats[0].total) * 100).toFixed(1) : 0,
        avgProcessingTime: inspectionStats[0]?.avgTime ? Math.round(inspectionStats[0].avgTime) : 0,
        efficiency: inspectionStats[0]?.total ? Math.min(100, ((inspectionStats[0].passed / inspectionStats[0].total) * 100 * 0.9)).toFixed(1) : 0
      },
      finishing: {
        totalProcessed: todayFinishing,
        completed: finishingStats[0]?.completed || 0,
        inProgress: finishingStats[0]?.inProgress || 0,
        completionRate: finishingStats[0]?.total ? ((finishingStats[0].completed / finishingStats[0].total) * 100).toFixed(1) : 0,
        avgProcessingTime: finishingStats[0]?.avgTime ? Math.round(finishingStats[0].avgTime) : 0,
        efficiency: finishingStats[0]?.total ? Math.min(100, ((finishingStats[0].completed / finishingStats[0].total) * 100 * 0.85)).toFixed(1) : 0
      },
      qualityControl: {
        totalProcessed: todayQC,
        passed: qcStats[0]?.passed || 0,
        failed: qcStats[0]?.failed || 0,
        passRate: qcStats[0]?.total ? ((qcStats[0].passed / qcStats[0].total) * 100).toFixed(1) : 0,
        avgProcessingTime: qcStats[0]?.avgTime ? Math.round(qcStats[0].avgTime) : 0,
        efficiency: qcStats[0]?.total ? Math.min(100, ((qcStats[0].passed / qcStats[0].total) * 100 * 0.95)).toFixed(1) : 0
      },
      delivery: {
        totalProcessed: todayDeliveries,
        delivered: deliveryStats[0]?.delivered || 0,
        pending: deliveryStats[0]?.pending || 0,
        deliveryRate: deliveryStats[0]?.total ? ((deliveryStats[0].delivered / deliveryStats[0].total) * 100).toFixed(1) : 0,
        avgProcessingTime: deliveryStats[0]?.avgTime ? Math.round(deliveryStats[0].avgTime) : 0,
        efficiency: deliveryStats[0]?.total ? Math.min(100, ((deliveryStats[0].delivered / deliveryStats[0].total) * 100 * 0.88)).toFixed(1) : 0
      }
    };

    res.json({
      processOverview: {
        totalUnitsProcessed: todayInspections + todayFinishing + todayQC + todayDeliveries,
        incomingInspection: todayInspections,
        finishing: todayFinishing,
        qualityControl: todayQC,
        delivery: todayDeliveries
      },
      processMatrix,
      userManagement: {
        assignedUsers: assignedUsers.length,
        unassignedUsers: unassignedUsers.length,
        totalUsers: assignedUsers.length + unassignedUsers.length
      },
      taskDistribution
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get user dashboard data
router.get('/user', auth, async (req, res) => {
  try {
    const userId = req.user._id;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get user's today's work
    const userInspections = await Inspection.countDocuments({
      inspectedBy: userId,
      createdAt: { $gte: today, $lt: tomorrow }
    });

    const userFinishing = await Finishing.countDocuments({
      processedBy: userId,
      createdAt: { $gte: today, $lt: tomorrow }
    });

    const userQC = await QualityControl.countDocuments({
      inspectedBy: userId,
      createdAt: { $gte: today, $lt: tomorrow }
    });

    const userDeliveries = await Delivery.countDocuments({
      managedBy: userId,
      createdAt: { $gte: today, $lt: tomorrow }
    });

    // Get user's assigned task
    const user = await User.findById(userId, 'assignedTask');

    res.json({
      assignedTask: user.assignedTask,
      todayWork: {
        incomingInspection: userInspections,
        finishing: userFinishing,
        qualityControl: userQC,
        delivery: userDeliveries,
        total: userInspections + userFinishing + userQC + userDeliveries
      },
      processOverview: {
        totalUnitsProcessed: 1500 // This could be calculated from all user's historical data
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get reports data
router.get('/reports/:type', auth, async (req, res) => {
  try {
    const { type } = req.params;
    const { startDate, endDate } = req.query;

    let dateFilter = {};
    if (startDate && endDate) {
      dateFilter = {
        createdAt: {
          $gte: new Date(startDate),
          $lte: new Date(endDate)
        }
      };
    }

    let reportData = {};

    switch (type) {
      case 'operations':
        const inspections = await Inspection.countDocuments(dateFilter);
        const finishing = await Finishing.countDocuments(dateFilter);
        const qualityControl = await QualityControl.countDocuments(dateFilter);
        const deliveries = await Delivery.countDocuments(dateFilter);

        reportData = {
          inspections,
          finishing,
          qualityControl,
          deliveries
        };
        break;

      case 'quality':
        const qcRecords = await QualityControl.find(dateFilter, 'qcStatus');
        const totalQC = qcRecords.length;
        const passedQC = qcRecords.filter(qc => qc.qcStatus === 'Pass').length;
        const failedQC = qcRecords.filter(qc => qc.qcStatus === 'Fail').length;

        reportData = {
          totalRecords: totalQC,
          passed: passedQC,
          failed: failedQC,
          passRate: totalQC > 0 ? ((passedQC / totalQC) * 100).toFixed(2) : 0,
          toleranceExceeded: 0 // This field might not exist in the model
        };
        break;

      case 'production':
        const totalInspections = await Inspection.countDocuments(dateFilter);
        const totalFinishing = await Finishing.countDocuments(dateFilter);
        const completedInspections = await Inspection.countDocuments({
          ...dateFilter,
          isCompleted: true
        });
        const completedFinishing = await Finishing.countDocuments({
          ...dateFilter,
          isCompleted: true
        });

        const toolUsage = await Finishing.aggregate([
          { $match: dateFilter },
          { $group: { _id: '$toolUsed', count: { $sum: 1 } } }
        ]);

        reportData = {
          totalProduction: totalInspections + totalFinishing,
          completedInspections,
          completedFinishing,
          toolUsage
        };
        break;

      case 'users':
        const totalUsers = await User.countDocuments();
        const activeUsers = await User.countDocuments({ isActive: true });
        const userData = await User.find({}, 'name role assignedTask completedToday totalAssigned');

        const userPerformance = userData.map(user => ({
          name: user.name,
          role: user.role,
          assignedTask: user.assignedTask,
          completedToday: user.completedToday,
          totalAssigned: user.totalAssigned,
          efficiency: user.totalAssigned > 0 ? (user.completedToday / user.totalAssigned) * 100 : 0
        }));

        reportData = {
          totalUsers,
          activeUsers,
          userPerformance
        };
        break;

      default:
        return res.status(400).json({ message: 'Invalid report type' });
    }

    res.json(reportData);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;