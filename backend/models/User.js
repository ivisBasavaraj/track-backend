const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },

  password: {
    type: String,
    required: true,
    minlength: 4
  },
  role: {
    type: String,
    enum: ['Admin', 'Supervisor', 'User'],
    default: 'User'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  assignedTask: {
    type: String,
    enum: ['Incoming Inspection', 'Finishing', 'Quality Control', 'Delivery', null],
    default: null
  },
  completedToday: {
    type: Number,
    default: 0
  },
  totalAssigned: {
    type: Number,
    default: 0
  },
  fcmTokens: [{
    token: {
      type: String,
      required: true
    },
    deviceId: {
      type: String,
      required: true
    },
    deviceType: {
      type: String,
      enum: ['android', 'ios', 'web'],
      default: 'android'
    },
    lastUsed: {
      type: Date,
      default: Date.now
    }
  }],
  pushNotificationsEnabled: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);