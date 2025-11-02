const mongoose = require('mongoose');

const toolUsageLogSchema = new mongoose.Schema({
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
  component_id: {
    type: String,
    required: true,
    trim: true
  },
  no_of_holes: {
    type: Number,
    required: true,
    min: 0
  },
  cutting_length: {
    type: Number,
    required: true,
    min: 0
  },
  usage_score: {
    type: Number,
    required: true,
    min: 0
  },
  cumulative_total_before: {
    type: Number,
    required: true,
    min: 0
  },
  cumulative_total_after: {
    type: Number,
    required: true,
    min: 0
  },
  tool_life_threshold: {
    type: Number,
    required: true
  },
  usage_percentage: {
    type: Number,
    default: 0
  },
  remaining_life: {
    type: Number,
    default: 0
  },
  alert_type: {
    type: String,
    enum: ['NONE', 'WARNING', 'CRITICAL'],
    default: 'NONE'
  },
  alert_triggered: {
    type: Boolean,
    default: false
  },
  operator_id: {
    type: String,
    trim: true
  },
  timestamp: {
    type: Date,
    default: Date.now,
    index: true
  }
}, { timestamps: true });

toolUsageLogSchema.index({ tool_id: 1, timestamp: -1 });

module.exports = mongoose.model('ToolUsageLog', toolUsageLogSchema);
