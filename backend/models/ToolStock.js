// File: models/ToolStock.js
const mongoose = require('mongoose');

const toolStockSchema = new mongoose.Schema(
  {
    toolId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MasterTool',
      index: true
    },

    toolName: {
      type: String,
      required: [true, 'Tool name is required'],
      trim: true
    },

    atcPocketNo: {
      type: String,
      trim: true,
      default: ''
    },

    toolRoomNo: {
      type: String,
      trim: true,
      default: ''
    },

    currentStock: {
      type: Number,
      required: [true, 'Current stock is required'],
      min: [0, 'Stock cannot be negative'],
      default: 0
    },

    minimumStock: {
      type: Number,
      required: [true, 'Minimum stock is required'],
      min: [0, 'Minimum stock cannot be negative'],
      default: 5
    },

    maximumStock: {
      type: Number,
      required: [true, 'Maximum stock is required'],
      min: [0, 'Maximum stock cannot be negative'],
      default: 50
    },

    reorderLevel: {
      type: Number,
      required: [true, 'Reorder level is required'],
      min: [0, 'Reorder level cannot be negative'],
      default: 10
    },

    reorderQuantity: {
      type: Number,
      required: [true, 'Reorder quantity is required'],
      min: [1, 'Reorder quantity must be at least 1'],
      default: 20
    },

    unit: {
      type: String,
      required: true,
      trim: true,
      default: 'pieces'
    },

    status: {
      type: String,
      enum: ['in_stock', 'low_stock', 'critical', 'out_of_stock'],
      default: 'in_stock'
    },

    lastUpdatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Last updated by user ID is required']
    },

    lastUpdatedByName: {
      type: String,
      required: true,
      trim: true
    },

    notes: {
      type: String,
      trim: true,
      default: ''
    },

    location: {
      type: String,
      trim: true,
      default: 'Tool Room'
    },

    costPerUnit: {
      type: Number,
      min: [0, 'Cost cannot be negative'],
      default: 0
    },

    lastRestockDate: {
      type: Date,
      default: null
    },

    createdAt: {
      type: Date,
      default: Date.now,
      index: true
    },

    updatedAt: {
      type: Date,
      default: Date.now
    }
  },
  {
    timestamps: true
  }
);

// Indexes for better query performance
toolStockSchema.index({ toolName: 1 });
toolStockSchema.index({ toolName: 1, atcPocketNo: 1 }, { unique: true });
toolStockSchema.index({ status: 1 });
toolStockSchema.index({ createdAt: -1 });
toolStockSchema.index({ lastUpdatedBy: 1 });

// Pre-save middleware to update status based on current stock
toolStockSchema.pre('save', function (next) {
  if (this.currentStock === 0) {
    this.status = 'out_of_stock';
  } else if (this.currentStock <= this.minimumStock) {
    this.status = 'critical';
  } else if (this.currentStock <= this.reorderLevel) {
    this.status = 'low_stock';
  } else {
    this.status = 'in_stock';
  }
  
  this.updatedAt = new Date();
  next();
});

// Pre-findOneAndUpdate middleware to update status
toolStockSchema.pre('findOneAndUpdate', function (next) {
  const update = this.getUpdate();
  
  if (update.currentStock !== undefined) {
    if (update.currentStock === 0) {
      update.status = 'out_of_stock';
    } else if (update.currentStock <= (update.minimumStock || this.getQuery().minimumStock)) {
      update.status = 'critical';
    } else if (update.currentStock <= (update.reorderLevel || this.getQuery().reorderLevel)) {
      update.status = 'low_stock';
    } else {
      update.status = 'in_stock';
    }
  }
  
  update.updatedAt = new Date();
  next();
});

// Static method to get low stock items
toolStockSchema.statics.getLowStockItems = function (options = {}) {
  const { limit = 10 } = options;
  
  return this.find({
    status: { $in: ['low_stock', 'critical', 'out_of_stock'] }
  })
    .populate('lastUpdatedBy', 'name username email')
    .sort({ status: 1, currentStock: 1 })
    .limit(limit)
    .lean();
};

// Static method to get all active stocks
toolStockSchema.statics.getActiveStocks = function (options = {}) {
  const { page = 1, limit = 20 } = options;
  const skip = (page - 1) * limit;
  
  return this.find()
    .populate('lastUpdatedBy', 'name username email')
    .sort({ toolName: 1 })
    .skip(skip)
    .limit(limit)
    .lean();
};

// Static method to search stocks
toolStockSchema.statics.searchStocks = function (searchTerm, options = {}) {
  const { page = 1, limit = 20 } = options;
  const skip = (page - 1) * limit;
  
  const searchRegex = { $regex: searchTerm, $options: 'i' };
  
  return this.find({
    $or: [
      { toolName: searchRegex },
      { atcPocketNo: searchRegex },
      { toolRoomNo: searchRegex },
      { location: searchRegex }
    ]
  })
    .populate('lastUpdatedBy', 'name username email')
    .sort({ toolName: 1 })
    .skip(skip)
    .limit(limit)
    .lean();
};

// Static method to get stock statistics
toolStockSchema.statics.getStatistics = function () {
  return this.aggregate([
    {
      $group: {
        _id: null,
        totalItems: { $sum: 1 },
        totalStock: { $sum: '$currentStock' },
        totalValue: { $sum: { $multiply: ['$currentStock', '$costPerUnit'] } },
        lowStockCount: {
          $sum: { $cond: [{ $eq: ['$status', 'low_stock'] }, 1, 0] }
        },
        criticalCount: {
          $sum: { $cond: [{ $eq: ['$status', 'critical'] }, 1, 0] }
        },
        outOfStockCount: {
          $sum: { $cond: [{ $eq: ['$status', 'out_of_stock'] }, 1, 0] }
        }
      }
    }
  ]);
};

// Instance method to update stock
toolStockSchema.methods.addStock = function (quantity, updatedByName) {
  this.currentStock += quantity;
  this.lastRestockDate = new Date();
  this.lastUpdatedByName = updatedByName;
  return this;
};

// Instance method to reduce stock
toolStockSchema.methods.removeStock = function (quantity, updatedByName) {
  if (this.currentStock >= quantity) {
    this.currentStock -= quantity;
    this.lastUpdatedByName = updatedByName;
    return this;
  }
  throw new Error('Insufficient stock');
};

// Instance method to check if needs reordering
toolStockSchema.methods.needsReordering = function () {
  return this.currentStock <= this.reorderLevel;
};

module.exports = mongoose.model('ToolStock', toolStockSchema);