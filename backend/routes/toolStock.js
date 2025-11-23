// File: routes/toolStock.js
const express = require('express');
const { auth, supervisorAuth } = require('../middleware/auth');
const ToolStock = require('../models/ToolStock');
const router = express.Router();

/**
 * @route   GET /api/tool-stock
 * @desc    Get all tool stocks with pagination
 * @access  Private/Supervisor
 * @query   { page?: number, limit?: number, search?: string }
 */
router.get('/', auth, supervisorAuth, async (req, res) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const pageNum = Math.max(1, parseInt(page) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(limit) || 20));

    let stocks;
    let total;

    if (search && search.trim()) {
      stocks = await ToolStock.searchStocks(search, {
        page: pageNum,
        limit: limitNum
      });
      total = await ToolStock.countDocuments({
        $or: [
          { toolName: { $regex: search, $options: 'i' } },
          { atcPocketNo: { $regex: search, $options: 'i' } },
          { toolRoomNo: { $regex: search, $options: 'i' } },
          { location: { $regex: search, $options: 'i' } }
        ]
      });
    } else {
      stocks = await ToolStock.getActiveStocks({
        page: pageNum,
        limit: limitNum
      });
      total = await ToolStock.countDocuments();
    }

    const totalPages = Math.ceil(total / limitNum);

    return res.json({
      success: true,
      data: stocks,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages
      }
    });
  } catch (error) {
    console.error('Error fetching tool stocks:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch tool stocks',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/tool-stock/low-stock
 * @desc    Get low stock items
 * @access  Private/Supervisor
 */
router.get('/low-stock', auth, supervisorAuth, async (req, res) => {
  try {
    const lowStockItems = await ToolStock.getLowStockItems({ limit: 50 });
    
    return res.json({
      success: true,
      data: lowStockItems,
      count: lowStockItems.length
    });
  } catch (error) {
    console.error('Error fetching low stock items:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch low stock items',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/tool-stock/statistics
 * @desc    Get stock statistics
 * @access  Private/Supervisor
 */
router.get('/statistics', auth, supervisorAuth, async (req, res) => {
  try {
    const stats = await ToolStock.getStatistics();
    
    return res.json({
      success: true,
      data: stats.length > 0 ? stats[0] : {
        totalItems: 0,
        totalStock: 0,
        totalValue: 0,
        lowStockCount: 0,
        criticalCount: 0,
        outOfStockCount: 0
      }
    });
  } catch (error) {
    console.error('Error fetching stock statistics:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch statistics',
      error: error.message
    });
  }
});

/**
 * @route   GET /api/tool-stock/:id
 * @desc    Get single tool stock
 * @access  Private/Supervisor
 */
router.get('/:id', auth, supervisorAuth, async (req, res) => {
  try {
    const stock = await ToolStock.findById(req.params.id)
      .populate('lastUpdatedBy', 'name username email');

    if (!stock) {
      return res.status(404).json({
        success: false,
        message: 'Tool stock not found'
      });
    }

    return res.json({
      success: true,
      data: stock
    });
  } catch (error) {
    console.error('Error fetching tool stock:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch tool stock',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/tool-stock
 * @desc    Create new tool stock
 * @access  Private/Supervisor
 * @body    { toolName, atcPocketNo?, toolRoomNo?, currentStock, minimumStock?, maximumStock?, reorderLevel?, unit?, location?, costPerUnit? }
 */
router.post('/', auth, supervisorAuth, async (req, res) => {
  try {
    const {
      toolName,
      atcPocketNo = '',
      toolRoomNo = '',
      currentStock,
      minimumStock = 5,
      maximumStock = 50,
      reorderLevel = 10,
      reorderQuantity = 20,
      unit = 'pieces',
      location = 'Tool Room',
      costPerUnit = 0,
      notes = ''
    } = req.body;

    if (!toolName || toolName.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Tool name is required'
      });
    }

    if (currentStock === undefined || currentStock === null) {
      return res.status(400).json({
        success: false,
        message: 'Current stock is required'
      });
    }

    // Check if stock already exists for this tool
    const existingStock = await ToolStock.findOne({
      toolName: toolName.trim(),
      atcPocketNo: atcPocketNo.trim()
    });

    if (existingStock) {
      return res.status(409).json({
        success: false,
        message: 'Tool stock already exists for this tool'
      });
    }

    const newStock = new ToolStock({
      toolName: toolName.trim(),
      atcPocketNo: atcPocketNo.trim(),
      toolRoomNo: toolRoomNo.trim(),
      currentStock: parseInt(currentStock) || 0,
      minimumStock: parseInt(minimumStock) || 5,
      maximumStock: parseInt(maximumStock) || 50,
      reorderLevel: parseInt(reorderLevel) || 10,
      reorderQuantity: parseInt(reorderQuantity) || 20,
      unit: unit.trim(),
      location: location.trim(),
      costPerUnit: parseFloat(costPerUnit) || 0,
      notes: notes.trim(),
      lastUpdatedBy: req.user._id,
      lastUpdatedByName: req.user.name || req.user.username,
      lastRestockDate: new Date()
    });

    await newStock.save();

    return res.status(201).json({
      success: true,
      message: 'Tool stock created successfully',
      data: newStock
    });
  } catch (error) {
    console.error('Error creating tool stock:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to create tool stock',
      error: error.message
    });
  }
});

/**
 * @route   PUT /api/tool-stock/:id
 * @desc    Update tool stock
 * @access  Private/Supervisor
 */
router.put('/:id', auth, supervisorAuth, async (req, res) => {
  try {
    const {
      toolName,
      atcPocketNo,
      toolRoomNo,
      currentStock,
      minimumStock,
      maximumStock,
      reorderLevel,
      reorderQuantity,
      unit,
      location,
      costPerUnit,
      notes
    } = req.body;

    const stock = await ToolStock.findById(req.params.id);

    if (!stock) {
      return res.status(404).json({
        success: false,
        message: 'Tool stock not found'
      });
    }

    // Update fields if provided
    if (toolName !== undefined) stock.toolName = toolName.trim();
    if (atcPocketNo !== undefined) stock.atcPocketNo = atcPocketNo.trim();
    if (toolRoomNo !== undefined) stock.toolRoomNo = toolRoomNo.trim();
    if (currentStock !== undefined) stock.currentStock = parseInt(currentStock) || 0;
    if (minimumStock !== undefined) stock.minimumStock = parseInt(minimumStock) || 5;
    if (maximumStock !== undefined) stock.maximumStock = parseInt(maximumStock) || 50;
    if (reorderLevel !== undefined) stock.reorderLevel = parseInt(reorderLevel) || 10;
    if (reorderQuantity !== undefined) stock.reorderQuantity = parseInt(reorderQuantity) || 20;
    if (unit !== undefined) stock.unit = unit.trim();
    if (location !== undefined) stock.location = location.trim();
    if (costPerUnit !== undefined) stock.costPerUnit = parseFloat(costPerUnit) || 0;
    if (notes !== undefined) stock.notes = notes.trim();

    stock.lastUpdatedBy = req.user._id;
    stock.lastUpdatedByName = req.user.name || req.user.username;
    if (currentStock !== undefined && currentStock > (req.body.previousStock || 0)) {
      stock.lastRestockDate = new Date();
    }

    await stock.save();

    return res.json({
      success: true,
      message: 'Tool stock updated successfully',
      data: stock
    });
  } catch (error) {
    console.error('Error updating tool stock:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update tool stock',
      error: error.message
    });
  }
});

/**
 * @route   DELETE /api/tool-stock/:id
 * @desc    Delete tool stock
 * @access  Private/Supervisor
 */
router.delete('/:id', auth, supervisorAuth, async (req, res) => {
  try {
    const stock = await ToolStock.findByIdAndDelete(req.params.id);

    if (!stock) {
      return res.status(404).json({
        success: false,
        message: 'Tool stock not found'
      });
    }

    return res.json({
      success: true,
      message: 'Tool stock deleted successfully',
      data: stock
    });
  } catch (error) {
    console.error('Error deleting tool stock:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to delete tool stock',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/tool-stock/:id/add-stock
 * @desc    Add stock to a tool
 * @access  Private/Supervisor
 * @body    { quantity: number }
 */
router.post('/:id/add-stock', auth, supervisorAuth, async (req, res) => {
  try {
    const { quantity } = req.body;

    if (!quantity || quantity <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Quantity must be greater than 0'
      });
    }

    const stock = await ToolStock.findById(req.params.id);

    if (!stock) {
      return res.status(404).json({
        success: false,
        message: 'Tool stock not found'
      });
    }

    stock.addStock(parseInt(quantity), req.user.name || req.user.username);
    await stock.save();

    return res.json({
      success: true,
      message: `Added ${quantity} units to stock`,
      data: stock
    });
  } catch (error) {
    console.error('Error adding stock:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to add stock',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/tool-stock/:id/remove-stock
 * @desc    Remove stock from a tool
 * @access  Private/Supervisor
 * @body    { quantity: number }
 */
router.post('/:id/remove-stock', auth, supervisorAuth, async (req, res) => {
  try {
    const { quantity } = req.body;

    if (!quantity || quantity <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Quantity must be greater than 0'
      });
    }

    const stock = await ToolStock.findById(req.params.id);

    if (!stock) {
      return res.status(404).json({
        success: false,
        message: 'Tool stock not found'
      });
    }

    if (stock.currentStock < parseInt(quantity)) {
      return res.status(400).json({
        success: false,
        message: `Insufficient stock. Current: ${stock.currentStock}, Requested: ${quantity}`
      });
    }

    stock.removeStock(parseInt(quantity), req.user.name || req.user.username);
    await stock.save();

    return res.json({
      success: true,
      message: `Removed ${quantity} units from stock`,
      data: stock
    });
  } catch (error) {
    console.error('Error removing stock:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to remove stock',
      error: error.message
    });
  }
});

/**
 * @route   POST /api/tool-stock/batch
 * @desc    Batch create tool stocks
 * @access  Private/Supervisor
 * @body    { tools: Array<ToolStockData> }
 */
router.post('/batch', auth, supervisorAuth, async (req, res) => {
  try {
    const { tools } = req.body;

    if (!Array.isArray(tools) || tools.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Tools array is required'
      });
    }

    const results = {
      success: 0,
      failed: 0,
      errors: []
    };

    for (let i = 0; i < tools.length; i++) {
      const tool = tools[i];
      try {
        const {
          toolName,
          atcPocketNo = '',
          toolRoomNo = '',
          currentStock,
          minimumStock = 5,
          maximumStock = 50,
          reorderLevel = 10,
          reorderQuantity = 20,
          unit = 'pieces',
          location = 'Tool Room',
          costPerUnit = 0,
          notes = ''
        } = tool;

        if (!toolName || toolName.trim() === '') {
          results.failed++;
          results.errors.push({ index: i, error: 'Tool name is required' });
          continue;
        }

        // Check if stock already exists
        const existingStock = await ToolStock.findOne({
          toolName: toolName.trim(),
          atcPocketNo: atcPocketNo.trim()
        });

        if (existingStock) {
          results.failed++;
          results.errors.push({ index: i, error: 'Tool already exists' });
          continue;
        }

        const newStock = new ToolStock({
          toolName: toolName.trim(),
          atcPocketNo: atcPocketNo.trim(),
          toolRoomNo: toolRoomNo.trim(),
          currentStock: parseInt(currentStock) || 0,
          minimumStock: parseInt(minimumStock) || 5,
          maximumStock: parseInt(maximumStock) || 50,
          reorderLevel: parseInt(reorderLevel) || 10,
          reorderQuantity: parseInt(reorderQuantity) || 20,
          unit: unit.trim(),
          location: location.trim(),
          costPerUnit: parseFloat(costPerUnit) || 0,
          notes: notes.trim(),
          lastUpdatedBy: req.user._id,
          lastUpdatedByName: req.user.name || req.user.username,
          lastRestockDate: new Date()
        });

        await newStock.save();
        results.success++;
      } catch (error) {
        results.failed++;
        results.errors.push({ index: i, error: error.message });
      }
    }

    return res.json({
      success: true,
      message: `Batch import completed: ${results.success} success, ${results.failed} failed`,
      data: results
    });
  } catch (error) {
    console.error('Error in batch import:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to batch import tools',
      error: error.message
    });
  }
});

module.exports = router;