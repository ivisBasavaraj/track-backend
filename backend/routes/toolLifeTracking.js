const express = require('express');
const { auth, supervisorAuth } = require('../middleware/auth');
const MasterTool = require('../models/MasterTool');
const ToolUsageLog = require('../models/ToolUsageLog');
const ToolAlert = require('../models/ToolAlert');
const { sendToolLifeAlert } = require('../services/emailService');
const { sendPushNotification, sendPushToMultipleDevices } = require('../services/pushNotificationService');

const router = express.Router();

// Get cumulative usage for a tool
async function getToolCumulativeUsage(toolId) {
  const logs = await ToolUsageLog.find({ tool_id: toolId }).sort({ timestamp: -1 }).limit(1);
  return logs.length > 0 ? logs[0].cumulative_total_after : 0;
}

// Get components used by tool
async function getComponentsUsedByTool(toolId) {
  const logs = await ToolUsageLog.find({ tool_id: toolId }).distinct('component_id');
  return logs;
}

async function sendSupervisorNotification(email, data, fcmTokens = []) {
  let emailSent = false;
  let pushSent = false;
  
  // Send email notification
  if (email && process.env.EMAIL_USER) {
    const emailResult = await sendToolLifeAlert(email, data);
    emailSent = emailResult.success;
  }
  
  // Send push notification
  if (fcmTokens && fcmTokens.length > 0) {
    const pushResult = await sendPushToMultipleDevices(fcmTokens, data);
    pushSent = pushResult.success;
  }
  
  return emailSent || pushSent;
}

/**
 * @route   POST /api/tool-life/usage/record
 * @desc    Record tool usage and calculate cumulative total
 * @access  Private
 */
router.post('/usage/record', auth, async (req, res) => {
  try {
    const { tool_id, component_id, no_of_holes, cutting_length, operator_id } = req.body;

    if (!tool_id || !component_id || no_of_holes === undefined || cutting_length === undefined) {
      return res.status(400).json({
        success: false,
        message: 'tool_id, component_id, no_of_holes, and cutting_length are required'
      });
    }

    const masterTool = await MasterTool.findOne({ tool_id });
    if (!masterTool) {
      return res.status(404).json({
        success: false,
        message: 'Tool not found in master list'
      });
    }

    const currentUsage = await getToolCumulativeUsage(tool_id);
    const usageScore = no_of_holes * cutting_length;
    const newCumulativeTotal = currentUsage + usageScore;
    const toolLifeThreshold = masterTool.tool_life_threshold;
    const orderThreshold = toolLifeThreshold * 0.75;
    const warningThreshold = toolLifeThreshold * 0.90;
    const usagePercentage = (newCumulativeTotal / toolLifeThreshold) * 100;
    const remainingLife = Math.max(0, toolLifeThreshold - newCumulativeTotal);

    let alertType = 'NONE';
    let alertSeverity = 'NONE';
    let toolStatus = 'ACTIVE';
    let shouldSendAlert = false;

    if (newCumulativeTotal >= toolLifeThreshold) {
      alertType = 'CRITICAL';
      alertSeverity = 'CRITICAL';
      toolStatus = 'END_OF_LIFE';
      shouldSendAlert = true;
    } else if (newCumulativeTotal >= warningThreshold) {
      alertType = 'WARNING';
      alertSeverity = 'WARNING';
      toolStatus = 'NEAR_END_OF_LIFE';
      shouldSendAlert = true;
    } else if (newCumulativeTotal >= orderThreshold) {
      alertType = 'ORDER';
      alertSeverity = 'INFO';
      shouldSendAlert = true;
    }

    await ToolUsageLog.create({
      tool_id,
      tool_name: masterTool.tool_name,
      component_id,
      no_of_holes,
      cutting_length,
      usage_score: usageScore,
      cumulative_total_before: currentUsage,
      cumulative_total_after: newCumulativeTotal,
      tool_life_threshold: toolLifeThreshold,
      usage_percentage: usagePercentage,
      remaining_life: remainingLife,
      alert_type: alertType,
      alert_triggered: shouldSendAlert,
      operator_id: operator_id || req.user._id.toString(),
      timestamp: new Date()
    });

    if (shouldSendAlert) {
      const componentsUsed = await getComponentsUsedByTool(tool_id);
      const existingAlert = await ToolAlert.findOne({
        tool_id,
        alert_type: alertType,
        alert_status: { $in: ['PENDING', 'SENT'] }
      });

      if (!existingAlert) {
        let alertMessage = '';
        let alertDescription = '';

        if (alertType === 'ORDER') {
          alertMessage = `INFO: Tool ID ${tool_id} (${masterTool.tool_name}) has reached 75% of its tool life. Current usage: ${newCumulativeTotal}/${toolLifeThreshold} (${usagePercentage.toFixed(2)}%). Tool life is ending soon - check availability to order replacement. Components affected: ${componentsUsed.join(', ')}`;
          alertDescription = 'Order notification - tool life ending soon, check availability to order';
        } else if (alertType === 'WARNING') {
          alertMessage = `CAUTION: Tool ID ${tool_id} (${masterTool.tool_name}) is nearing its tool life limit. Current usage: ${newCumulativeTotal}/${toolLifeThreshold} (${usagePercentage.toFixed(2)}%). Remaining usage: ${remainingLife} units. Please prepare for tool maintenance/replacement. Components affected: ${componentsUsed.join(', ')}`;
          alertDescription = 'Warning notification - tool approaching end of life, prepare for maintenance';
        } else if (alertType === 'CRITICAL') {
          alertMessage = `ALERT: Tool ID ${tool_id} (${masterTool.tool_name}) has reached its tool life limit of ${toolLifeThreshold}. Cumulative usage: ${newCumulativeTotal} (${usagePercentage.toFixed(2)}%). Immediate maintenance/replacement required. Components affected: ${componentsUsed.join(', ')}`;
          alertDescription = 'Critical notification - immediate action required';
        }

        const alert = await ToolAlert.create({
          tool_id,
          tool_name: masterTool.tool_name,
          tool_life_threshold: toolLifeThreshold,
          cumulative_usage: newCumulativeTotal,
          alert_type: alertType,
          alert_severity: alertSeverity,
          usage_percentage: usagePercentage,
          remaining_life: remainingLife,
          components_used: componentsUsed,
          supervisor_email: masterTool.supervisor_email,
          alert_status: 'PENDING',
          alert_message: alertMessage,
          alert_description: alertDescription,
          created_date: new Date()
        });

        if (masterTool.supervisor_email) {
          await sendSupervisorNotification(masterTool.supervisor_email, {
            tool_id,
            tool_name: masterTool.tool_name,
            cumulative_usage: newCumulativeTotal,
            threshold: toolLifeThreshold,
            usage_percentage: usagePercentage,
            remaining_life: remainingLife,
            components: componentsUsed,
            alert_type: alertType,
            alert_severity: alertSeverity
          });

          alert.alert_status = 'SENT';
          alert.sent_date = new Date();
          await alert.save();
        }
      }
    }

    masterTool.status = toolStatus;
    await masterTool.save();

    return res.status(200).json({
      success: true,
      message: 'Tool usage recorded successfully',
      data: {
        tool_id,
        tool_name: masterTool.tool_name,
        usage_score: usageScore,
        cumulative_total: newCumulativeTotal,
        tool_life_threshold: toolLifeThreshold,
        usage_percentage: usagePercentage.toFixed(2),
        remaining_life: remainingLife,
        alert_type: alertType,
        alert_severity: alertSeverity,
        threshold_reached: newCumulativeTotal >= toolLifeThreshold,
        warning_threshold_reached: newCumulativeTotal >= warningThreshold,
        status: toolStatus,
        recommendation: toolStatus === 'END_OF_LIFE' ? 'Tool requires immediate replacement' :
          toolStatus === 'NEAR_END_OF_LIFE' ? 'Tool nearing end of life, prepare for replacement' :
            'Tool usage normal, continue monitoring'
      }
    });

  } catch (error) {
    console.error('Record usage error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error recording tool usage',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   GET /api/tool-life/:toolId/status
 * @desc    Get current status of a tool
 * @access  Private
 */
router.get('/:toolId/status', auth, async (req, res) => {
  try {
    const { toolId } = req.params;
    const tool_id = parseInt(toolId);

    const masterTool = await MasterTool.findOne({ tool_id });
    if (!masterTool) {
      return res.status(404).json({
        success: false,
        message: 'Tool not found'
      });
    }

    const cumulativeUsage = await getToolCumulativeUsage(tool_id);
    const componentsUsed = await getComponentsUsedByTool(tool_id);
    const lastLog = await ToolUsageLog.findOne({ tool_id }).sort({ timestamp: -1 });
    const usagePercentage = (cumulativeUsage / masterTool.tool_life_threshold) * 100;
    const remainingLife = Math.max(0, masterTool.tool_life_threshold - cumulativeUsage);
    const warningThreshold = masterTool.tool_life_threshold * 0.90;

    let alertStatus = 'NONE';
    if (cumulativeUsage >= masterTool.tool_life_threshold) {
      alertStatus = 'CRITICAL';
    } else if (cumulativeUsage >= warningThreshold) {
      alertStatus = 'WARNING';
    }

    return res.status(200).json({
      success: true,
      message: 'Tool status retrieved successfully',
      data: {
        tool_id,
        tool_name: masterTool.tool_name,
        holder_name: masterTool.holder_name,
        cumulative_usage: cumulativeUsage,
        tool_life_threshold: masterTool.tool_life_threshold,
        usage_percentage: usagePercentage.toFixed(2),
        remaining_life: remainingLife,
        threshold_reached: cumulativeUsage >= masterTool.tool_life_threshold,
        warning_threshold_reached: cumulativeUsage >= warningThreshold,
        alert_status: alertStatus,
        components_used: componentsUsed,
        last_used: lastLog ? lastLog.timestamp : null,
        status: masterTool.status,
        recommendation: masterTool.status === 'END_OF_LIFE' ? 'Tool requires immediate replacement' :
          masterTool.status === 'NEAR_END_OF_LIFE' ? 'Tool nearing end of life, prepare for replacement' :
            'Tool usage normal, continue monitoring'
      }
    });

  } catch (error) {
    console.error('Get status error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error fetching tool status',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   GET /api/tool-life/alerts/active
 * @desc    Get all active alerts
 * @access  Private
 */
router.get('/alerts/active', auth, async (req, res) => {
  try {
    const alerts = await ToolAlert.find({
      alert_status: { $in: ['PENDING', 'SENT'] }
    }).sort({ created_date: -1 });

    return res.status(200).json({
      success: true,
      message: 'Active alerts retrieved successfully',
      data: { alerts }
    });

  } catch (error) {
    console.error('Get alerts error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error fetching alerts',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   POST /api/tool-life/alerts/notify
 * @desc    Send notification to supervisor
 * @access  Private/Supervisor
 */
router.post('/alerts/notify', auth, supervisorAuth, async (req, res) => {
  try {
    const { alert_id, supervisor_email } = req.body;

    const alert = await ToolAlert.findById(alert_id);
    if (!alert) {
      return res.status(404).json({
        success: false,
        message: 'Alert not found'
      });
    }

    await sendSupervisorNotification(supervisor_email, {
      tool_id: alert.tool_id,
      tool_name: alert.tool_name,
      cumulative_usage: alert.cumulative_usage,
      threshold: alert.tool_life_threshold,
      usage_percentage: alert.usage_percentage,
      remaining_life: alert.remaining_life,
      components: alert.components_used,
      alert_type: alert.alert_type,
      alert_severity: alert.alert_severity
    });

    alert.alert_status = 'SENT';
    alert.sent_date = new Date();
    await alert.save();

    return res.status(200).json({
      success: true,
      message: `Notification sent successfully to ${supervisor_email}`,
      data: { alert_id, status: 'SENT' }
    });

  } catch (error) {
    console.error('Send notification error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error sending notification',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   POST /api/tool-life/:toolId/reset
 * @desc    Reset tool after maintenance
 * @access  Private/Supervisor
 */
router.post('/:toolId/reset', auth, supervisorAuth, async (req, res) => {
  try {
    const { toolId } = req.params;
    const { maintenance_notes, maintenance_date, technician_id } = req.body;
    const tool_id = parseInt(toolId);

    const masterTool = await MasterTool.findOne({ tool_id });
    if (!masterTool) {
      return res.status(404).json({
        success: false,
        message: 'Tool not found'
      });
    }

    const previousTotal = await getToolCumulativeUsage(tool_id);

    await ToolUsageLog.create({
      tool_id,
      tool_name: masterTool.tool_name,
      component_id: 'MAINTENANCE_RESET',
      no_of_holes: 0,
      cutting_length: 0,
      usage_score: 0,
      cumulative_total_before: previousTotal,
      cumulative_total_after: 0,
      tool_life_threshold: masterTool.tool_life_threshold,
      usage_percentage: 0,
      remaining_life: masterTool.tool_life_threshold,
      alert_type: 'NONE',
      alert_triggered: false,
      operator_id: technician_id || req.user._id.toString(),
      timestamp: new Date()
    });

    masterTool.status = 'ACTIVE';
    await masterTool.save();

    await ToolAlert.updateMany(
      { tool_id, alert_status: { $in: ['PENDING', 'SENT'] } },
      { $set: { alert_status: 'ACKNOWLEDGED', acknowledged_date: new Date() } }
    );

    return res.status(200).json({
      success: true,
      message: 'Tool reset successfully',
      data: {
        tool_id,
        cumulative_usage_reset: true,
        new_cumulative_total: 0,
        previous_total: previousTotal,
        status: 'ACTIVE'
      }
    });

  } catch (error) {
    console.error('Reset tool error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error resetting tool',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   POST /api/tool-life/master/create
 * @desc    Create master tool entry
 * @access  Private/Supervisor
 */
router.post('/master/create', auth, supervisorAuth, async (req, res) => {
  try {
    const { tool_id, tool_name, holder_name, atc_pocket_no, tool_room_no, tool_life_threshold, supervisor_email } = req.body;

    if (!tool_id || !tool_name || !tool_life_threshold) {
      return res.status(400).json({
        success: false,
        message: 'tool_id, tool_name, and tool_life_threshold are required'
      });
    }

    const existingTool = await MasterTool.findOne({ tool_id });
    if (existingTool) {
      return res.status(409).json({
        success: false,
        message: 'Tool with this ID already exists'
      });
    }

    const masterTool = await MasterTool.create({
      tool_id,
      tool_name,
      holder_name: holder_name || '',
      atc_pocket_no: atc_pocket_no || '',
      tool_room_no: tool_room_no || '',
      tool_life_threshold,
      supervisor_email: supervisor_email || '',
      status: 'ACTIVE'
    });

    return res.status(201).json({
      success: true,
      message: 'Master tool created successfully',
      data: { masterTool }
    });

  } catch (error) {
    console.error('Create master tool error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error creating master tool',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   GET /api/tool-life/master/all
 * @desc    Get all master tools
 * @access  Private
 */
router.get('/master/all', auth, async (req, res) => {
  try {
    const masterTools = await MasterTool.find().sort({ tool_id: 1 });

    const toolsWithUsage = await Promise.all(masterTools.map(async (tool) => {
      const cumulativeUsage = await getToolCumulativeUsage(tool.tool_id);
      const usagePercentage = (cumulativeUsage / tool.tool_life_threshold) * 100;
      const remainingLife = Math.max(0, tool.tool_life_threshold - cumulativeUsage);

      return {
        ...tool.toObject(),
        cumulative_usage: cumulativeUsage,
        usage_percentage: usagePercentage.toFixed(2),
        remaining_life: remainingLife
      };
    }));

    return res.status(200).json({
      success: true,
      message: 'Master tools retrieved successfully',
      data: { masterTools: toolsWithUsage }
    });

  } catch (error) {
    console.error('Get master tools error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error fetching master tools',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   GET /api/tool-life/:toolId/history
 * @desc    Get tool usage history
 * @access  Private
 */
router.get('/:toolId/history', auth, async (req, res) => {
  try {
    const { toolId } = req.params;
    const tool_id = parseInt(toolId);

    const logs = await ToolUsageLog.find({ tool_id }).sort({ timestamp: -1 });

    return res.status(200).json({
      success: true,
      message: 'Tool history retrieved successfully',
      data: { logs }
    });

  } catch (error) {
    console.error('Get history error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error fetching tool history',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   GET /api/tool-life/master/:toolId
 * @desc    Get single master tool
 * @access  Private
 */
router.get('/master/:toolId', auth, async (req, res) => {
  try {
    const tool_id = parseInt(req.params.toolId);
    const masterTool = await MasterTool.findOne({ tool_id });
    
    if (!masterTool) {
      return res.status(404).json({
        success: false,
        message: 'Tool not found'
      });
    }

    return res.status(200).json({
      success: true,
      data: { masterTool }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error fetching tool',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   PATCH /api/tool-life/master/:toolId
 * @desc    Update master tool
 * @access  Private/Supervisor
 */
router.patch('/master/:toolId', auth, supervisorAuth, async (req, res) => {
  try {
    const tool_id = parseInt(req.params.toolId);
    const { tool_name, holder_name, atc_pocket_no, tool_room_no, tool_life_threshold, supervisor_email } = req.body;

    const masterTool = await MasterTool.findOne({ tool_id });
    if (!masterTool) {
      return res.status(404).json({
        success: false,
        message: 'Tool not found'
      });
    }

    if (tool_name) masterTool.tool_name = tool_name;
    if (holder_name !== undefined) masterTool.holder_name = holder_name;
    if (atc_pocket_no !== undefined) masterTool.atc_pocket_no = atc_pocket_no;
    if (tool_room_no !== undefined) masterTool.tool_room_no = tool_room_no;
    if (tool_life_threshold) masterTool.tool_life_threshold = tool_life_threshold;
    if (supervisor_email !== undefined) masterTool.supervisor_email = supervisor_email;

    await masterTool.save();

    return res.status(200).json({
      success: true,
      message: 'Tool updated successfully',
      data: { masterTool }
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error updating tool',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   DELETE /api/tool-life/master/:toolId
 * @desc    Delete master tool
 * @access  Private/Supervisor
 */
router.delete('/master/:toolId', auth, supervisorAuth, async (req, res) => {
  try {
    const tool_id = parseInt(req.params.toolId);
    const masterTool = await MasterTool.findOneAndDelete({ tool_id });
    
    if (!masterTool) {
      return res.status(404).json({
        success: false,
        message: 'Tool not found'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Tool deleted successfully'
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error deleting tool',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router;
