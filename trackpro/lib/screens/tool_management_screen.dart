import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/tool_list_model.dart';
import '../services/tools_service.dart';
import '../utils/excel_processor.dart';
import 'tool_view_screen.dart';
import 'master_tool_management_screen.dart';

class ToolManagementScreen extends StatefulWidget {
  const ToolManagementScreen({super.key});

  @override
  State<ToolManagementScreen> createState() => _ToolManagementScreenState();
}

class _ToolManagementScreenState extends State<ToolManagementScreen> {
  final ToolsService _toolsService = ToolsService();

  // Upload state
  bool _isUploading = false;
  String? _uploadMessage;
  bool _uploadSuccess = false;

  // Existing tool lists
  final List<ToolList> _toolLists = [];
  bool _isLoadingLists = false;
  String _searchTerm = '';
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  // Form state
  final TextEditingController _toolNameController = TextEditingController();
  final TextEditingController _sheetTypeController = TextEditingController();
  final TextEditingController _sheetDisplayNameController = TextEditingController();
  bool _overwriteExisting = false;

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _selectedFilePath;
  List<Map<String, dynamic>> _parsedPreviewRows = [];
  String? _parsedPreviewError;

  @override
  void initState() {
    super.initState();
    _fetchToolLists();
  }

  @override
  void dispose() {
    _toolNameController.dispose();
    _sheetTypeController.dispose();
    _sheetDisplayNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchToolLists() async {
    setState(() {
      _isLoadingLists = true;
    });

    try {
      final results = await _toolsService.getAllToolLists(
        page: _currentPage,
        limit: _pageSize,
      );

      setState(() {
        _toolLists
          ..clear()
          ..addAll(results);
        // TODO: Wire total pages once the service returns pagination metadata
        _totalPages = 1;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tool lists: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLists = false;
        });
      }
    }
  }

  Future<void> _pickCsvFile() async {
    setState(() {
      _parsedPreviewRows = [];
      _parsedPreviewError = null;
      _selectedFileBytes = null;
      _selectedFileName = null;
      _selectedFilePath = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final pickedFile = result.files.single;
    if (pickedFile.bytes == null) {
      setState(() {
        _parsedPreviewError = 'Unable to access the selected file.';
      });
      return;
    }

    final bytes = pickedFile.bytes!;

    setState(() {
      _selectedFileBytes = bytes;
      _selectedFileName = pickedFile.name;
      _selectedFilePath = null;
    });

    // Skip preview for CSV files - backend will handle parsing
    setState(() {
      _parsedPreviewRows = [];
      _parsedPreviewError = null;
    });
  }

  Future<void> _uploadToolList() async {
    FocusScope.of(context).unfocus();

    final toolName = _toolNameController.text.trim();
    final sheetType = _sheetTypeController.text.trim().isEmpty
        ? null
        : _sheetTypeController.text.trim();
    final sheetDisplayName =
        _sheetDisplayNameController.text.trim().isEmpty
            ? null
            : _sheetDisplayNameController.text.trim();

    if (toolName.isEmpty) {
      _showSnackBar('Please enter a tool list name.', Colors.orange);
      return;
    }

    if (_selectedFileBytes == null) {
      _showSnackBar('Please select a CSV file to upload.', Colors.orange);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadMessage = null;
      _uploadSuccess = false;
    });

    try {
      final response = await _toolsService.uploadToolList(
        toolName: toolName,
        csvFileBytes: _selectedFileBytes,
        csvFilePath: null,
        sheetType: sheetType,
        sheetDisplayName: sheetDisplayName,
        overwrite: _overwriteExisting,
      );

      final message = response['message'] ?? 'Upload completed successfully.';

      setState(() {
        _uploadMessage = message;
        _uploadSuccess = true;
        _selectedFileBytes = null;
        _selectedFileName = null;
        _selectedFilePath = null;
        _parsedPreviewRows = [];
        _parsedPreviewError = null;
        _toolNameController.clear();
        _sheetTypeController.clear();
        _sheetDisplayNameController.clear();
        _overwriteExisting = false;
      });

      await _fetchToolLists();
    } catch (error) {
      setState(() {
        _uploadMessage = error.toString();
        _uploadSuccess = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  List<ToolList> get _filteredToolLists {
    if (_searchTerm.isEmpty) {
      return _toolLists;
    }

    final lowerSearch = _searchTerm.toLowerCase();
    return _toolLists
        .where(
          (tool) =>
              tool.toolName.toLowerCase().contains(lowerSearch) ||
              tool.uploaderName.toLowerCase().contains(lowerSearch),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tool Management', style: TextStyle(fontWeight: FontWeight.w600)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideLayout = constraints.maxWidth > 1000;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.engineering, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Supervisor Tool Management',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Upload and manage tool lists with full control',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MasterToolManagementScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.build_circle),
                          label: const Text('Master Tools'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  isWideLayout
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildUploadCard(),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 5,
                              child: _buildToolListCard(),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUploadCard(),
                            const SizedBox(height: 24),
                            _buildToolListCard(),
                          ],
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_upload, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Upload Tool List',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Provide metadata and upload a CSV file to import tool data',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _toolNameController,
                decoration: InputDecoration(
                  labelText: 'Tool List Name *',
                  hintText: 'e.g. AMS-141 COLUMN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sheetTypeController,
                decoration: InputDecoration(
                  labelText: 'Sheet Type',
                  hintText: 'master, reference, operational',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sheetDisplayNameController,
                decoration: InputDecoration(
                  labelText: 'Sheet Display Name',
                  hintText: 'Friendly name shown in the UI',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.text_fields),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Overwrite existing data'),
              subtitle: const Text(
                'Enable this to replace the existing sheet for the same tool name and type.',
              ),
              value: _overwriteExisting,
              onChanged: (value) {
                setState(() {
                  _overwriteExisting = value;
                });
              },
            ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isUploading ? null : _pickCsvFile,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.file_open, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedFileName != null
                                  ? 'Selected: $_selectedFileName'
                                  : 'Select CSV File',
                              style: TextStyle(
                                color: _selectedFileName != null ? Colors.green.shade700 : Colors.grey.shade700,
                                fontWeight: _selectedFileName != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (_selectedFileName != null)
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_parsedPreviewError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _parsedPreviewError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else if (_parsedPreviewRows.isNotEmpty)
              _buildPreviewTable(),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 24),
                  label: Text(
                    _isUploading ? 'Uploading…' : 'Upload Tool List',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _isUploading ? null : _uploadToolList,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (_uploadMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _uploadSuccess ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _uploadSuccess
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _uploadSuccess ? Icons.check_circle : Icons.error_outline,
                        color: _uploadSuccess
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _uploadMessage!,
                          style: TextStyle(
                            color: _uploadSuccess
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTable() {
    final previewHeaders = _parsedPreviewRows.first.keys.toList();
    final previewRows = _parsedPreviewRows.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview (first 5 rows)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: previewHeaders
                  .map(
                    (header) => DataColumn(
                      label: Text(
                        header,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
              rows: previewRows
                  .map(
                    (row) => DataRow(
                      cells: previewHeaders
                          .map(
                            (header) => DataCell(
                              Text(row[header]?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolListCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.blue.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storage, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Existing Tool Lists',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by tool or uploader…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchTerm.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchTerm = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchTerm = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_isLoadingLists)
                const Center(child: CircularProgressIndicator())
              else if (_filteredToolLists.isEmpty)
                _buildEmptyState()
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildToolDataTable(),
                    const SizedBox(height: 16),
                    _buildPaginationControls(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.blue.shade700),
            dataRowHeight: 64,
            columns: const [
              DataColumn(label: Text('Tool Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Sheet Count', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Total Tools', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Total Holes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Cutting Length', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Last Updated', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Uploader', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
            ],
            rows: _filteredToolLists.asMap().entries.map((entry) {
              final index = entry.key;
              final toolList = entry.value;
              final formattedUpdatedAt = toolList.updatedAt.toLocal();
              final sheetCount = toolList.sheets.length;
              final formattedDate = '${formattedUpdatedAt.day.toString().padLeft(2, '0')}/'
                  '${formattedUpdatedAt.month.toString().padLeft(2, '0')}/'
                  '${formattedUpdatedAt.year.toString()}';

              return DataRow(
                color: MaterialStateProperty.all(
                  index.isEven ? Colors.grey.shade50 : Colors.white,
                ),
                cells: [
                  DataCell(Text(toolList.toolName, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('$sheetCount', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  DataCell(Text('${toolList.totalTools}', style: TextStyle(color: Colors.grey.shade800))),
                  DataCell(
                    Text(
                      '${toolList.totalHoles}',
                      style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    Text(
                      toolList.totalCuttingLength.toStringAsFixed(2),
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(formattedDate, style: TextStyle(color: Colors.grey.shade600))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(toolList.uploaderName, style: TextStyle(color: Colors.purple.shade900)),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.visibility_outlined, color: Colors.blue.shade700),
                            tooltip: 'View data',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ToolViewScreen(toolName: toolList.toolName),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                            tooltip: 'Delete',
                            onPressed: () {
                              _confirmDeletion(toolList);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Page $_currentPage of $_totalPages'),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 1
              ? () {
                  setState(() {
                    _currentPage -= 1;
                  });
                  _fetchToolLists();
      }
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < _totalPages
              ? () {
                  setState(() {
                    _currentPage += 1;
                  });
                  _fetchToolLists();
    }
              : null,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchTerm.isEmpty
                ? 'No tool lists available yet.'
                : 'No results for "$_searchTerm".',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload a CSV file to create a new tool list.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
}

  Future<void> _confirmDeletion(ToolList toolList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tool List'),
        content: Text(
          'This will permanently remove "$toolList.toolName" and all associated sheets. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _toolsService.deleteToolList(toolList.id);
        if (success) {
          _showSnackBar('Tool list deleted successfully.', Colors.green);
          await _fetchToolLists();
        }
      } catch (error) {
        _showSnackBar('Error deleting tool list: $error', Colors.red);
      }
    }
  }
}
