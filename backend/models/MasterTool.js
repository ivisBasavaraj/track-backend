const mongoose = require('mongoose');

const masterToolSchema = new mongoose.Schema({
  tool_id: {
    type: Number,
    required: true,
    unique: true,
    index: true
  },
  tool_name: {
    type: String,
    required: true,
    trim: true
  },
  holder_name: {
    type: String,
    trim: true,
    default: ''
  },
  atc_pocket_no: {
    type: String,
    trim: true,
    default: ''
  },
  tool_room_no: {
    type: String,
    trim: true,
    default: ''
  },
  tool_life_threshold: {
    type: Number,
    required: true,
    min: 1
  },
  status: {
    type: String,
    enum: ['ACTIVE', 'NEAR_END_OF_LIFE', 'END_OF_LIFE', 'MAINTENANCE_REQUIRED', 'REPLACED'],
    default: 'ACTIVE'
  },
  supervisor_email: {
    type: String,
    trim: true,
    lowercase: true
  },
  created_date: {
    type: Date,
    default: Date.now
  }
}, { timestamps: true });

module.exports = mongoose.model('MasterTool', masterToolSchema);
