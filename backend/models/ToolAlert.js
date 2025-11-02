const mongoose = require('mongoose');

const toolAlertSchema = new mongoose.Schema({
  tool_id: {
    type: Number,
    required: true,
    index: true
  },
  tool_name: {
    type: String,
    required: true,
    trim: true
  },
  tool_life_threshold: {
    type: Number,
    required: true
  },
  cumulative_usage: {
    type: Number,
    required: true
  },
  alert_type: {
    type: String,
    enum: ['WARNING', 'CRITICAL'],
    required: true
  },
  alert_severity: {
    type: String,
    enum: ['WARNING', 'CRITICAL'],
    required: true
  },
  usage_percentage: {
    type: Number,
    required: true
  },
  remaining_life: {
    type: Number,
    required: true
  },
  components_used: [{
    type: String,
    trim: true
  }],
  supervisor_email: {
    type: String,
    trim: true,
    lowercase: true
  },
  alert_status: {
    type: String,
    enum: ['PENDING', 'SENT', 'ACKNOWLEDGED'],
    default: 'PENDING'
  },
  alert_message: {
    type: String,
    required: true
  },
  alert_description: {
    type: String,
    required: true
  },
  created_date: {
    type: Date,
    default: Date.now,
    index: true
  },
  sent_date: {
    type: Date
  },
  acknowledged_date: {
    type: Date
  }
}, { timestamps: true });

toolAlertSchema.index({ tool_id: 1, alert_type: 1, alert_status: 1 });

module.exports = mongoose.model('ToolAlert', toolAlertSchema);
