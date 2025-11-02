// File: routes/tools.js
const express = require('express');
const path = require('path');
const fs = require('fs');
const fsPromises = require('fs/promises');
const { parse } = require('csv-parse/sync');
const { auth, supervisorAuth } = require('../middleware/auth');
const csvUpload = require('../middleware/csvUpload');
const ToolList = require('../models/ToolList');
const mongoose = require('mongoose');

const router = express.Router();

/**
 * @route   POST /api/tools/upload
 * @desc    Upload CSV tool list (Supervisor only)
 * @access  Private/Supervisor
 * @body    { toolName: string, sheetType?: string, overwrite?: boolean, csv: file }
 */
router.post('/upload', auth, supervisorAuth, csvUpload.single('csv'), async (req, res) => {
  try {
    const uploadDir = path.join(__dirname, '../uploads');

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No CSV file uploaded'
      });
    }

    const { toolName, sheetType } = req.body;
    if (!toolName || typeof toolName !== 'string' || toolName.trim() === '') {
      await safeUnlink(req.file.path, uploadDir);
      return res.status(400).json({
        success: false,
        message: 'Tool name is required'
      });
    }

    const normalizedToolName = toolName.trim();
    const normalizedSheetType = typeof sheetType === 'string' && sheetType.trim() !== ''
      ? sheetType.trim().toLowerCase()
      : 'master';

    const normalizedPath = path.normalize(req.file.path);
    if (!normalizedPath.startsWith(uploadDir)) {
      await safeUnlink(req.file.path, uploadDir);
      return res.status(400).json({
        success: false,
        message: 'Invalid file path'
      });
    }

    const existingTool = await ToolList.findOne({
      toolName: normalizedToolName,
      sheetType: normalizedSheetType
    });

    if (existingTool) {
      const overwriteFlag = typeof req.body.overwrite === 'string'
        ? req.body.overwrite.toLowerCase() === 'true'
        : Boolean(req.body.overwrite);

      if (!overwriteFlag) {
        await safeUnlink(normalizedPath, uploadDir);
        return res.status(409).json({
          success: false,
          message: 'Tool list with this name and sheet type already exists. Set overwrite=true to replace it.'
        });
      }
    }

    const previousFilePath = existingTool && existingTool.filePath && existingTool.filePath !== normalizedPath
      ? existingTool.filePath
      : null;

    let csvContent;
    try {
      csvContent = await fsPromises.readFile(normalizedPath, 'utf-8');
    } catch (readError) {
      await safeUnlink(normalizedPath, uploadDir);
      return res.status(400).json({
        success: false,
        message: 'Unable to read uploaded CSV file'
      });
    }

    if (!csvContent || csvContent.trim() === '') {
      await safeUnlink(normalizedPath, uploadDir);
      return res.status(400).json({
        success: false,
        message: 'CSV file is empty'
      });
    }

    let parsedRows;
    try {
      parsedRows = parse(csvContent, {
        columns: true,
        skip_empty_lines: false,
        relax_column_count: true,
        relax_quotes: true,
        trim: true,
        skip_records_with_empty_values: false
      });
    } catch (parseError) {
      await safeUnlink(normalizedPath, uploadDir);
      return res.status(400).json({
        success: false,
        message: 'Failed to parse CSV file',
        details: process.env.NODE_ENV === 'development' ? parseError.message : undefined
      });
    }

    if (!Array.isArray(parsedRows) || parsedRows.length === 0) {
      await safeUnlink(normalizedPath, uploadDir);
      return res.status(400).json({
        success: false,
        message: 'CSV file has no data'
      });
    }

    const toolData = [];
    let fallbackSlNo = 1;

    parsedRows.forEach((row) => {
      const rowData = row || {};

      const slNoRaw = rowData['SL.NO'] ?? rowData['SL NO'] ?? rowData['slNo'] ?? '';
      const atcPocketNoRaw = rowData['ATC POCKET-NO'] ?? rowData['ATC POCKET NO'] ?? rowData['atcPocketNo'] ?? '';
      const toolNameRaw = rowData['TOOL NAME'] ?? rowData['toolName'] ?? rowData['Tool Name'] ?? '';
      const holderNameRaw = rowData['HOLDER NAME'] ?? rowData['holderName'] ?? rowData['Holder Name'] ?? '';
      const toolRoomNoRaw = rowData['TOOL ROOM NO'] ?? rowData['TOOL ROOM NUMBER'] ?? rowData['toolRoomNo'] ?? '';
      const noOfHolesRaw = rowData['NO OF HOLES IN COMPONENT'] ?? rowData['NO OF HOLES'] ?? rowData['noOfHoles'] ?? '';
      const cuttingLengthRaw = rowData['CUTTING LENGTH'] ?? rowData['cuttingLength'] ?? rowData['Cutting Length'] ?? '';
      const remarksRaw = rowData['REMARKS'] ?? rowData['remarks'] ?? rowData['Remarks'] ?? '';
      const toolLifeTimeRaw = rowData['TOOL LIFE TIME'] ?? rowData['toolLifeTime'] ?? rowData['Tool Life Time'] ?? '';

      const parsedHoles = parseNumber(noOfHolesRaw);
      const parsedCuttingLength = parseNumber(cuttingLengthRaw);

      // Keep all rows including empty ones for formatting preservation

      const parsedSlNo = parseNumber(slNoRaw);
      const slNo = parsedSlNo > 0 ? parsedSlNo : fallbackSlNo;

      toolData.push({
        slNo,
        atcPocketNo: toTrimmedString(atcPocketNoRaw),
        toolName: toTrimmedString(toolNameRaw),
        holderName: toTrimmedString(holderNameRaw),
        toolRoomNo: toTrimmedString(toolRoomNoRaw),
        noOfHolesInComponent: parsedHoles,
        cuttingLength: parsedCuttingLength,
        remarks: toTrimmedString(remarksRaw),
        toolLifeTime: parseNumber(toolLifeTimeRaw)
      });

      fallbackSlNo = slNo >= fallbackSlNo ? slNo + 1 : fallbackSlNo + 1;
    });

    if (toolData.length === 0) {
      await safeUnlink(normalizedPath, uploadDir);
      return res.status(400).json({
        success: false,
        message: 'No valid data found in CSV file'
      });
    }

    const totalHoles = toolData.reduce((sum, tool) => sum + tool.noOfHolesInComponent, 0);
    const totalCuttingLength = toolData.reduce((sum, tool) => sum + tool.cuttingLength, 0);
    const totalTools = toolData.length;

    const toolListData = {
      toolName: normalizedToolName,
      sheetType: normalizedSheetType,
      toolData,
      fileName: req.file.originalname,
      filePath: normalizedPath,
      uploadedBy: req.user._id,
      uploaderName: req.user.name || req.user.username,
      uploaderEmail: req.user.email,
      totalTools,
      totalHoles,
      totalCuttingLength,
      sheetName: 'csv',
      uploadedAt: new Date()
    };

    const toolList = await ToolList.findOneAndUpdate(
      { toolName: normalizedToolName, sheetType: normalizedSheetType },
      { $set: toolListData },
      { new: true, upsert: true, setDefaultsOnInsert: true }
    ).populate('uploadedBy', 'name username email role');

    if (previousFilePath) {
      await safeUnlink(previousFilePath, uploadDir);
    }

    return res.status(existingTool ? 200 : 201).json({
      success: true,
      message: existingTool ? 'Tool list overwritten successfully' : 'Tool list uploaded successfully',
      data: {
        toolList: {
          id: toolList._id,
          toolName: toolList.toolName,
          sheetType: toolList.sheetType,
          totalTools: toolList.totalTools,
          totalHoles: toolList.totalHoles,
          totalCuttingLength: toolList.totalCuttingLength,
          fileName: toolList.fileName,
          uploadedBy: toolList.uploadedBy,
          uploadedAt: toolList.uploadedAt
        }
      }
    });

  } catch (error) {
    console.error('Upload error:', error);

    if (req.file) {
      const uploadDir = path.join(__dirname, '../uploads');
      await safeUnlink(req.file.path, uploadDir);
    }

    return res.status(500).json({
      success: false,
      message: 'Error uploading tool list',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   GET /api/tools
 * @desc    Get all tool lists
 * @access  Private
 * @query   { search: string, page: number, limit: number }
 */
router.get('/', auth, async (req, res) => {
  try {
    const { search, page = 1, limit = 10, sheetType } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Build query
    let query = {};
    if (search) {
      query = {
        $or: [
          { toolName: { $regex: search, $options: 'i' } },
          { fileName: { $regex: search, $options: 'i' } },
          { uploaderName: { $regex: search, $options: 'i' } }
        ]
      };
    }

    if (sheetType && typeof sheetType === 'string' && sheetType.trim() !== '') {
      query = {
        ...query,
        sheetType: sheetType.trim().toLowerCase()
      };
    }

    // Fetch tool lists with pagination
    const toolLists = await ToolList.find(query)
      .populate('uploadedBy', 'name username email role')
      .sort({ uploadedAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    // Get total count for pagination
    const total = await ToolList.countDocuments(query);

    return res.status(200).json({
      success: true,
      message: 'Tool lists retrieved successfully',
      data: {
        toolLists: toolLists,
        pagination: {
          total: total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });

  } catch (error) {
    console.error('Fetch error:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Error fetching tool lists',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   GET /api/tools/name/:toolName
 * @desc    Get tool list by name
 * @access  Private
 */
router.get('/name/:toolName', auth, async (req, res) => {
  try {
    const { toolName } = req.params;
    const { sheetType } = req.query;

    if (!toolName || toolName.trim() === '') {
      return res.status(400).json({ 
        success: false,
        message: 'Tool name is required' 
      });
    }

    const normalizedToolName = toolName.trim();
    const query = { toolName: normalizedToolName };

    if (sheetType && typeof sheetType === 'string' && sheetType.trim() !== '') {
      query.sheetType = sheetType.trim().toLowerCase();
    }

    const toolSheets = await ToolList.find(query)
      .populate('uploadedBy', 'name username email role')
      .sort({ sheetType: 1, uploadedAt: -1 });

    if (!toolSheets || toolSheets.length === 0) {
      return res.status(404).json({ 
        success: false,
        message: 'Tool list not found' 
      });
    }

    const totals = toolSheets.reduce(
      (acc, sheet) => {
        acc.totalTools += sheet.totalTools || 0;
        acc.totalHoles += sheet.totalHoles || 0;
        acc.totalCuttingLength += sheet.totalCuttingLength || 0;
        return acc;
      },
      { totalTools: 0, totalHoles: 0, totalCuttingLength: 0 }
    );

    return res.status(200).json({
      success: true,
      message: 'Tool sheets retrieved successfully',
      data: {
        toolName: normalizedToolName,
        totals,
        sheets: toolSheets.map(sheet => ({
          id: sheet._id,
          sheetType: sheet.sheetType,
          sheetDisplayName: sheet.sheetDisplayName || null,
          sheetName: sheet.sheetName,
          totalTools: sheet.totalTools,
          totalHoles: sheet.totalHoles,
          totalCuttingLength: sheet.totalCuttingLength,
          fileName: sheet.fileName,
          uploadedAt: sheet.uploadedAt,
          uploadedBy: sheet.uploadedBy,
          toolData: sheet.toolData
        }))
      }
    });

  } catch (error) {
    console.error('Fetch error:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Error fetching tool list',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   GET /api/tools/:id
 * @desc    Get tool list by ID
 * @access  Private
 */
router.get('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;

    // Validate MongoDB ObjectId
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ 
        success: false,
        message: 'Invalid tool list ID' 
      });
    }

    const toolList = await ToolList.findById(id)
      .populate('uploadedBy', 'name username email role');

    if (!toolList) {
      return res.status(404).json({ 
        success: false,
        message: 'Tool list not found' 
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Tool list retrieved successfully',
      data: {
        toolList: toolList
      }
    });

  } catch (error) {
    console.error('Fetch error:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Error fetching tool list',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   GET /api/tools/by-name/:toolName (duplicate route removed)
 * @desc    Get tool list by name
 * @access  Private
 */
// This route was moved above to fix route precedence
router.get('/by-name/:toolName', auth, async (req, res) => {
  // Redirect to the main /name/:toolName route
  return res.redirect(`/api/tools/name/${req.params.toolName}`);
});

/**
 * @route   PUT /api/tools/:id
 * @desc    Update tool list (Supervisor only)
 * @access  Private/Supervisor
 */
router.put('/:id', auth, supervisorAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const { toolName, sheetType, sheetDisplayName, toolData } = req.body;

    // Validate MongoDB ObjectId
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ 
        success: false,
        message: 'Invalid tool list ID' 
      });
    }

    // Validate input
    if (!toolName || toolName.trim() === '') {
      return res.status(400).json({ 
        success: false,
        message: 'Tool name is required' 
      });
    }

    const normalizedToolName = toolName.trim();
    const normalizedSheetType = typeof sheetType === 'string' && sheetType.trim() !== ''
      ? sheetType.trim().toLowerCase()
      : 'master';

    if (!Array.isArray(toolData) || toolData.length === 0) {
      return res.status(400).json({ 
        success: false,
        message: 'Tool data is required and must be non-empty' 
      });
    }

    // Check for duplicate combination
    const existingTool = await ToolList.findOne({
      toolName: normalizedToolName,
      sheetType: normalizedSheetType,
      _id: { $ne: id }
    });

    if (existingTool) {
      return res.status(409).json({ 
        success: false,
        message: 'Another tool list with this name and sheet type already exists' 
      });
    }

    // Clean tool data
    const cleanedToolData = toolData.map(tool => ({
      slNo: parseNumber(tool.slNo),
      atcPocketNo: String(tool.atcPocketNo ?? '').trim(),
      toolName: String(tool.toolName ?? '').trim(),
      holderName: String(tool.holderName ?? '').trim(),
      toolRoomNo: String(tool.toolRoomNo ?? '').trim(),
      noOfHolesInComponent: parseNumber(tool.noOfHolesInComponent),
      cuttingLength: parseNumber(tool.cuttingLength),
      remarks: String(tool.remarks ?? '').trim(),
      toolLifeTime: parseNumber(tool.toolLifeTime)
    }));

    // Calculate totals
    const totalHoles = cleanedToolData.reduce((sum, tool) => sum + tool.noOfHolesInComponent, 0);
    const totalCuttingLength = cleanedToolData.reduce((sum, tool) => sum + tool.cuttingLength, 0);
    const totalTools = cleanedToolData.length;

    // Update tool list
    const updatePayload = {
      toolName: normalizedToolName,
      sheetType: normalizedSheetType,
      toolData: cleanedToolData,
      totalTools,
      totalHoles,
      totalCuttingLength,
      updatedAt: new Date()
    };

    if (sheetDisplayName && typeof sheetDisplayName === 'string') {
      updatePayload.sheetDisplayName = sheetDisplayName.trim();
    }

    const updatedToolList = await ToolList.findByIdAndUpdate(
      id,
      updatePayload,
      { new: true, runValidators: true }
    ).populate('uploadedBy', 'name username email role');

    if (!updatedToolList) {
      return res.status(404).json({ 
        success: false,
        message: 'Tool list not found' 
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Tool list updated successfully',
      data: {
        toolList: updatedToolList
      }
    });

  } catch (error) {
    console.error('Update error:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Error updating tool list',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   DELETE /api/tools/:id
 * @desc    Delete tool list (Supervisor only)
 * @access  Private/Supervisor
 */
router.delete('/:id', auth, supervisorAuth, async (req, res) => {
  try {
    const { id } = req.params;

    // Validate MongoDB ObjectId
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ 
        success: false,
        message: 'Invalid tool list ID' 
      });
    }

    // Find and delete tool list
    const toolList = await ToolList.findByIdAndDelete(id);

    if (!toolList) {
      return res.status(404).json({ 
        success: false,
        message: 'Tool list not found' 
      });
    }

    // Delete associated file if it exists
    if (toolList.filePath) {
      const uploadDir = path.join(__dirname, '../uploads');
      await safeUnlink(toolList.filePath, uploadDir);
    }

    return res.status(200).json({
      success: true,
      message: 'Tool list deleted successfully',
      data: {
        toolList: toolList
      }
    });

  } catch (error) {
    console.error('Delete error:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Error deleting tool list',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   DELETE /api/tools
 * @desc    Delete multiple tool lists (Supervisor only)
 * @access  Private/Supervisor
 */
router.delete('/', auth, supervisorAuth, async (req, res) => {
  try {
    const { ids } = req.body;

    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ 
        success: false,
        message: 'No tool list IDs provided' 
      });
    }

    // Validate all IDs are valid MongoDB ObjectIds
    const invalidIds = ids.filter(id => !mongoose.Types.ObjectId.isValid(id));
    if (invalidIds.length > 0) {
      return res.status(400).json({ 
        success: false,
        message: 'Invalid tool list IDs provided' 
      });
    }

    // Delete all tool lists
    const result = await ToolList.deleteMany({ _id: { $in: ids } });

    return res.status(200).json({
      success: true,
      message: `${result.deletedCount} tool lists deleted successfully`,
      data: {
        deletedCount: result.deletedCount
      }
    });

  } catch (error) {
    console.error('Batch delete error:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Error deleting tool lists',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route   GET /api/tools/user/:userId
 * @desc    Get tool lists uploaded by a specific user
 * @access  Private
 */
router.get('/user/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 10 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Validate MongoDB ObjectId
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ 
        success: false,
        message: 'Invalid user ID' 
      });
    }

    // Fetch tool lists
    const toolLists = await ToolList.find({ uploadedBy: userId })
      .populate('uploadedBy', 'name username email role')
      .sort({ uploadedAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    // Get total count
    const total = await ToolList.countDocuments({ uploadedBy: userId });

    return res.status(200).json({
      success: true,
      message: 'User tool lists retrieved successfully',
      data: {
        toolLists: toolLists,
        pagination: {
          total: total,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });

  } catch (error) {
    console.error('Fetch error:', error);
    return res.status(500).json({ 
      success: false,
      message: 'Error fetching user tool lists',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

async function safeUnlink(filePath, uploadDir) {
  if (!filePath) {
    return;
  }

  try {
    const normalizedPath = path.normalize(filePath);
    if (uploadDir && !normalizedPath.startsWith(uploadDir)) {
      return;
    }

    if (await fileExists(normalizedPath)) {
      await fsPromises.unlink(normalizedPath);
    }
  } catch (error) {
    console.error('Error removing file:', error);
  }
}

async function fileExists(targetPath) {
  try {
    await fsPromises.access(targetPath, fs.constants.F_OK);
    return true;
  } catch (err) {
    return false;
  }
}

function toTrimmedString(value) {
  if (value === null || value === undefined) {
    return '';
  }

  return String(value).trim();
}

function isBlank(value) {
  if (value === null || value === undefined) {
    return true;
  }

  if (typeof value === 'string') {
    return value.trim() === '';
  }

  if (typeof value === 'number') {
    return Number.isNaN(value);
  }

  return false;
}

function parseNumber(value) {
  if (value === null || value === undefined) {
    return 0;
  }

  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : 0;
  }

  if (typeof value === 'string') {
    const cleaned = value.replace(/,/g, '').trim();
    if (cleaned === '') {
      return 0;
    }

    const parsed = Number(cleaned);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  return 0;
}

module.exports = router;