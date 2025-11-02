// File: models/ToolList.js
const mongoose = require('mongoose');

const toolListSchema = new mongoose.Schema(
  {
    toolName: {
      type: String,
      required: [true, 'Tool name is required'],
      trim: true,
      minlength: [1, 'Tool name cannot be empty'],
      maxlength: [100, 'Tool name cannot exceed 100 characters']
    },

    sheetType: {
      type: String,
      required: [true, 'Sheet type is required'],
      trim: true,
      lowercase: true,
      default: 'master',
      maxlength: [50, 'Sheet type cannot exceed 50 characters']
    },

    toolData: [
      {
        slNo: {
          type: Number,
          required: true,
          min: 1
        },
        atcPocketNo: {
          type: String,
          required: true,
          trim: true
        },
        toolName: {
          type: String,
          required: true,
          trim: true
        },
        holderName: {
          type: String,
          trim: true,
          default: ''
        },
        toolRoomNo: {
          type: String,
          trim: true,
          default: ''
        },
        noOfHolesInComponent: {
          type: Number,
          required: true,
          min: 0,
          default: 0
        },
        cuttingLength: {
          type: Number,
          required: true,
          min: 0,
          default: 0
        },
        remarks: {
          type: String,
          trim: true,
          default: ''
        },
        toolLifeTime: {
          type: Number,
          min: 0,
          default: 0
        },
        _id: false // Disable default _id for array items
      }
    ],

    fileName: {
      type: String,
      required: true,
      trim: true
    },

    filePath: {
      type: String,
      default: null
    },

    uploadedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Uploader information is required']
    },

    uploaderName: {
      type: String,
      required: true,
      trim: true
    },

    uploaderEmail: {
      type: String,
      trim: true,
      lowercase: true
    },

    totalTools: {
      type: Number,
      required: true,
      min: 0,
      default: 0
    },

    totalHoles: {
      type: Number,
      required: true,
      min: 0,
      default: 0
    },

    totalCuttingLength: {
      type: Number,
      required: true,
      min: 0,
      default: 0
    },

    sheetName: {
      type: String,
      default: 'Sheet1',
      trim: true
    },

    sheetDisplayName: {
      type: String,
      trim: true
    },

    status: {
      type: String,
      enum: ['active', 'inactive', 'archived'],
      default: 'active'
    },

    description: {
      type: String,
      trim: true,
      default: ''
    },

    tags: [
      {
        type: String,
        trim: true
      }
    ],

    uploadedAt: {
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
    timestamps: false // We're managing timestamps manually
  }
);

// Indexes for better query performance
toolListSchema.index({ toolName: 1 });
toolListSchema.index({ toolName: 1, sheetType: 1 }, { unique: true });
toolListSchema.index({ uploadedBy: 1, uploadedAt: -1 });
toolListSchema.index({ status: 1 });
toolListSchema.index({ uploadedAt: -1 });

// Pre-save middleware to update totals
toolListSchema.pre('save', function (next) {
  if (!this.sheetType || typeof this.sheetType !== 'string') {
    this.sheetType = 'master';
  } else {
    this.sheetType = this.sheetType.trim().toLowerCase() || 'master';
  }

  if (this.sheetDisplayName && typeof this.sheetDisplayName === 'string') {
    this.sheetDisplayName = this.sheetDisplayName.trim();
  }

  if (this.toolData && this.toolData.length > 0) {
    this.totalTools = this.toolData.length;
    this.totalHoles = this.toolData.reduce((sum, tool) => sum + (tool.noOfHolesInComponent || 0), 0);
    this.totalCuttingLength = this.toolData.reduce((sum, tool) => sum + (tool.cuttingLength || 0), 0);
  }
  next();
});

// Pre-findOneAndUpdate middleware
toolListSchema.pre('findOneAndUpdate', function (next) {
  const update = this.getUpdate();

  if (update.sheetType && typeof update.sheetType === 'string') {
    update.sheetType = update.sheetType.trim().toLowerCase() || 'master';
  }

  if (update.sheetDisplayName && typeof update.sheetDisplayName === 'string') {
    update.sheetDisplayName = update.sheetDisplayName.trim();
  }

  if (update.toolData && Array.isArray(update.toolData)) {
    update.totalTools = update.toolData.length;
    update.totalHoles = update.toolData.reduce((sum, tool) => sum + (tool.noOfHolesInComponent || 0), 0);
    update.totalCuttingLength = update.toolData.reduce((sum, tool) => sum + (tool.cuttingLength || 0), 0);
    update.updatedAt = new Date();
  }
  next();
});

// Instance method to get tool by slNo
toolListSchema.methods.getToolBySlNo = function (slNo) {
  return this.toolData.find(tool => tool.slNo === slNo);
};

// Instance method to add a tool
toolListSchema.methods.addTool = function (toolObject) {
  const newTool = {
    slNo: toolObject.slNo || this.toolData.length + 1,
    atcPocketNo: toolObject.atcPocketNo || '',
    toolName: toolObject.toolName || '',
    holderName: toolObject.holderName || '',
    toolRoomNo: toolObject.toolRoomNo || '',
    noOfHolesInComponent: toolObject.noOfHolesInComponent || 0,
    cuttingLength: toolObject.cuttingLength || 0,
    remarks: toolObject.remarks || '',
    toolLifeTime: toolObject.toolLifeTime || 0
  };
  this.toolData.push(newTool);
  return this;
};

// Instance method to remove a tool by slNo
toolListSchema.methods.removeTool = function (slNo) {
  this.toolData = this.toolData.filter(tool => tool.slNo !== slNo);
  return this;
};

// Instance method to update a tool
toolListSchema.methods.updateTool = function (slNo, updatedData) {
  const tool = this.toolData.find(t => t.slNo === slNo);
  if (tool) {
    Object.assign(tool, updatedData);
  }
  return this;
};

// Instance method to get tool count
toolListSchema.methods.getToolCount = function () {
  return this.toolData.length;
};

// Instance method to get total holes
toolListSchema.methods.getTotalHoles = function () {
  return this.toolData.reduce((sum, tool) => sum + (tool.noOfHolesInComponent || 0), 0);
};

// Instance method to get total cutting length
toolListSchema.methods.getTotalCuttingLength = function () {
  return this.toolData.reduce((sum, tool) => sum + (tool.cuttingLength || 0), 0);
};

// Instance method to get average cutting length
toolListSchema.methods.getAverageCuttingLength = function () {
  if (this.toolData.length === 0) return 0;
  return this.getTotalCuttingLength() / this.toolData.length;
};

// Static method to get tool lists by user
toolListSchema.statics.getByUser = function (userId, options = {}) {
  const { page = 1, limit = 10, status = 'active' } = options;
  const skip = (page - 1) * limit;

  return this.find({
    uploadedBy: userId,
    status: status
  })
    .select('-toolData') // Exclude large toolData array for list view
    .populate('uploadedBy', 'name username email role')
    .sort({ uploadedAt: -1 })
    .skip(skip)
    .limit(limit)
    .lean();
};

// Static method to search tool lists
toolListSchema.statics.searchTools = function (searchTerm, options = {}) {
  const { page = 1, limit = 10, status = 'active' } = options;
  const skip = (page - 1) * limit;

  const searchRegex = { $regex: searchTerm, $options: 'i' };

  return this.find({
    status: status,
    $or: [
      { toolName: searchRegex },
      { fileName: searchRegex },
      { uploaderName: searchRegex },
      { description: searchRegex }
    ]
  })
    .populate('uploadedBy', 'name username email role')
    .sort({ uploadedAt: -1 })
    .skip(skip)
    .limit(limit);
};

// Static method to get statistics
toolListSchema.statics.getStatistics = function () {
  return this.aggregate([
    {
      $group: {
        _id: null,
        totalLists: { $sum: 1 },
        totalTools: { $sum: '$totalTools' },
        totalHoles: { $sum: '$totalHoles' },
        totalCuttingLength: { $sum: '$totalCuttingLength' },
        avgToolsPerList: { $avg: '$totalTools' },
        avgHolesPerList: { $avg: '$totalHoles' },
        avgCuttingLengthPerList: { $avg: '$totalCuttingLength' }
      }
    }
  ]);
};

// Virtual for formatted upload date
toolListSchema.virtual('formattedUploadDate').get(function () {
  return this.uploadedAt ? this.uploadedAt.toLocaleDateString() : '';
});

// Ensure virtuals are included when converting to JSON
toolListSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('ToolList', toolListSchema);