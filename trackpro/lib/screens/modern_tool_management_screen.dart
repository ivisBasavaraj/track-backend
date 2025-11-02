// File: lib/screens/modern_tool_management_screen.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../models/tool_list_model.dart';
import '../services/tools_service.dart';
import '../utils/excel_processor.dart';
import '../ui/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_search.dart';
import '../widgets/modern_loading.dart';
import 'tool_view_screen.dart';
import 'modern_tool_view_screen.dart';
import 'master_tool_management_screen.dart';

class ModernToolManagementScreen extends StatefulWidget {
  const ModernToolManagementScreen({super.key});

  @override
  State<ModernToolManagementScreen> createState() => _ModernToolManagementScreenState();
}

class _ModernToolManagementScreenState extends State<ModernToolManagementScreen>
    with TickerProviderStateMixin {
  final ToolsService _toolsService = ToolsService();

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

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
  final TextEditingController _searchController = TextEditingController();
  bool _overwriteExisting = false;

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  String? _selectedFilePath;
  List<Map<String, dynamic>> _parsedPreviewRows = [];
  String? _parsedPreviewError;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: AppDurations.slow,
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: AppDurations.medium,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AppCurves.easeInOutQuart,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _initializeScreen();
  }

  void _initializeScreen() async {
    await _fetchToolLists();
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _toolNameController.dispose();
    _sheetTypeController.dispose();
    _sheetDisplayNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchToolLists([int page = 1]) async {
    if (_isLoadingLists) return;

    setState(() {
      _isLoadingLists = true;
    });

    try {
      final toolLists = await _toolsService.getAllToolLists(
        page: page,
        limit: _pageSize,
      );

      setState(() {
        if (page == 1) {
          _toolLists.clear();
        }
        _toolLists.addAll(toolLists);
        _currentPage = page;
        _totalPages = 1;
      });
    } catch (error) {
      _showModernSnackBar('Error loading tool lists: $error', isError: true);
    } finally {
      setState(() {
        _isLoadingLists = false;
      });
    }
  }

  void _showModernSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _pickFile() async {
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

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.single;
    if (pickedFile.bytes == null) {
      setState(() {
        _parsedPreviewError = 'Unable to access the selected file.';
      });
      return;
    }

    setState(() {
      _selectedFileBytes = pickedFile.bytes!;
      _selectedFileName = pickedFile.name;
      _parsedPreviewRows = [];
      _parsedPreviewError = null;
    });
  }

  Future<void> _uploadToolList() async {
    if (_isUploading) return;
    
    FocusScope.of(context).unfocus();

    final toolName = _toolNameController.text.trim();
    final sheetType = _sheetTypeController.text.trim().isEmpty
        ? null
        : _sheetTypeController.text.trim();
    final sheetDisplayName = _sheetDisplayNameController.text.trim().isEmpty
        ? null
        : _sheetDisplayNameController.text.trim();

    if (toolName.isEmpty) {
      _showModernSnackBar('Please enter a tool list name.', isError: true);
      return;
    }

    if (_selectedFileBytes == null) {
      _showModernSnackBar('Please select a CSV file to upload.', isError: true);
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

      _showModernSnackBar(message);
      await _fetchToolLists();
    } catch (error) {
      setState(() {
        _uploadMessage = error.toString();
        _uploadSuccess = false;
      });
      _showModernSnackBar('Upload failed: $error', isError: true);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchTerm = value;
      _currentPage = 1;
    });
    _fetchToolLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isUploading,
        loadingText: "Uploading tool list...",
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  _buildModernAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUploadSection(),
                          const SizedBox(height: 24),
                          _buildExistingToolsSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.build_circle_outlined,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tool Management',
                  style: AppTheme.displaySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload and manage your tool lists',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return ModernCard(
      title: 'Upload New Tool List',
      subtitle: 'Import tools from CSV files',
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.upload_file_rounded,
          color: AppTheme.successColor,
          size: 20,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildFormFields(),
          const SizedBox(height: 20),
          _buildFileSelector(),
          const SizedBox(height: 20),
          _buildUploadActions(),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
            duration: AppDurations.medium,
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 20.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildModernTextField(
                controller: _toolNameController,
                label: 'Tool List Name',
                hint: 'Enter a name for your tool list',
                icon: Icons.label_outline,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _sheetTypeController,
                label: 'Sheet Type (Optional)',
                hint: 'e.g., Machining Tools, Cutting Tools',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _sheetDisplayNameController,
                label: 'Display Name (Optional)',
                hint: 'Custom display name',
                icon: Icons.display_settings_outlined,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overwrite Existing',
                            style: AppTheme.labelLarge.copyWith(
                              color: AppTheme.warningColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check this box to replace an existing tool list with the same name',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: _overwriteExisting,
                        onChanged: (value) {
                          setState(() {
                            _overwriteExisting = value ?? false;
                          });
                        },
                        activeColor: AppTheme.warningColor,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.surfaceColor,
      ),
      child: TextField(
        controller: controller,
        style: AppTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
          hintStyle: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _selectedFileName != null
            ? AppTheme.successColor.withOpacity(0.05)
            : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedFileName != null
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.borderColor,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _selectedFileName != null
                ? Icons.check_circle_outline
                : Icons.cloud_upload_outlined,
            color: _selectedFileName != null
                ? AppTheme.successColor
                : AppTheme.textTertiary,
            size: 48,
          ),
          const SizedBox(height: 12),
          if (_selectedFileName != null) ...[
            Text(
              'File Selected',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: AppTheme.successColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _selectedFileName!,
                      style: AppTheme.labelMedium.copyWith(
                        color: AppTheme.successColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Choose CSV File',
              style: AppTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a CSV file containing your tool data',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ModernButton(
            text: _selectedFileName != null ? 'Change File' : 'Browse Files',
            onPressed: _pickFile,
            type: _selectedFileName != null
                ? ModernButtonType.outline
                : ModernButtonType.primary,
            icon: Icons.folder_open_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadActions() {
    return Row(
      children: [
        Expanded(
          child: ModernButton(
            text: 'Upload Tool List',
            onPressed: _canUpload() ? _uploadToolList : null,
            type: ModernButtonType.primary,
            icon: Icons.upload_rounded,
            isLoading: _isUploading,
            height: 48,
          ),
        ),
        const SizedBox(width: 12),
        ModernButton(
          text: 'Master Tools',
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MasterToolManagementScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: AppCurves.easeInOutQuart,
                    )),
                    child: child,
                  );
                },
                transitionDuration: AppDurations.medium,
              ),
            );
          },
          type: ModernButtonType.outline,
          icon: Icons.settings_outlined,
        ),
      ],
    );
  }

  Widget _buildExistingToolsSection() {
    return ModernCard(
      title: 'Existing Tool Lists',
      subtitle: '${_toolLists.length} tool lists available',
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.infoColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.list_alt_rounded,
          color: AppTheme.infoColor,
          size: 20,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ModernSearchBar(
            controller: _searchController,
            hintText: 'Search tool lists...',
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          if (_isLoadingLists)
            const Center(
              child: ModernLoadingIndicator(
                size: 32,
                style: LoadingStyle.pulse,
              ),
            )
          else if (_toolLists.isEmpty)
            _buildEmptyState()
          else
            _buildToolListGrid(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppTheme.textTertiary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _searchTerm.isNotEmpty ? 'No matching tool lists found' : 'No tool lists uploaded yet',
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchTerm.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Upload your first CSV file to get started',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildToolListGrid() {
    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: AppDurations.medium,
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 30.0,
            child: FadeInAnimation(child: widget),
          ),
          children: _toolLists.map((toolList) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ModernCard(
                padding: const EdgeInsets.all(16),
                onTap: () => _navigateToToolView(toolList),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.precision_manufacturing_outlined,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            toolList.toolName,
                            style: AppTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${toolList.sheets.length} sheet${toolList.sheets.length != 1 ? 's' : ''} • ${toolList.fileName}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildInfoChip(
                                Icons.calendar_today_outlined,
                                _formatDate(toolList.createdAt),
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                Icons.engineering_outlined,
                                '${toolList.totalTools} tools',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.textTertiary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.textTertiary,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  bool _canUpload() {
    return _toolNameController.text.trim().isNotEmpty && 
           _selectedFileName != null && 
           !_isUploading;
  }

  void _navigateToToolView(ToolList toolList) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ModernToolViewScreen(toolList: toolList),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppCurves.easeInOutQuart,
            )),
            child: child,
          );
        },
        transitionDuration: AppDurations.medium,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}