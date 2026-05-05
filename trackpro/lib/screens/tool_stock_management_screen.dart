// File: lib/screens/tool_stock_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../models/tool_stock_model.dart';
import '../services/api_service.dart';
import '../ui/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_button.dart' hide FloatingActionButton;
import '../widgets/modern_search.dart';
import '../widgets/modern_loading.dart';
import '../utils/csv_parser.dart';

class ToolStockManagementScreen extends StatefulWidget {
  const ToolStockManagementScreen({super.key});

  @override
  State<ToolStockManagementScreen> createState() => _ToolStockManagementScreenState();
}

class _ToolStockManagementScreenState extends State<ToolStockManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  List<ToolStock> _stocks = [];
  bool _isLoading = true;
  String _searchTerm = '';
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 20;
  
  ToolStockStatistics? _statistics;
  final bool _showLowStockOnly = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadStocks();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final result = await ApiService.getToolStocks(
        page: _currentPage,
        limit: _pageSize,
        search: _searchTerm.isNotEmpty ? _searchTerm : null,
      );

      if (mounted) {
        setState(() {
          _stocks = (result['data'] as List)
              .map((item) => ToolStock.fromMap(item as Map<String, dynamic>))
              .toList();
          
          _totalPages = result['pagination']?['totalPages'] ?? 1;
          _isLoading = false;
        });
      }

      _loadStatistics();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showErrorSnackbar('Failed to load stocks: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final result = await ApiService.getStockStatistics();
      
      if (mounted) {
        setState(() {
          _statistics = ToolStockStatistics.fromMap(result['data']);
        });
      }
    } catch (e) {
      // Silently fail for statistics
    }
  }

  Future<void> _loadLowStockItems() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final result = await ApiService.getLowStockItems();

      if (mounted) {
        setState(() {
          _stocks = (result['data'] as List)
              .map((item) => ToolStock.fromMap(item as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showErrorSnackbar('Failed to load low stock items: $e');
    }
  }

  void _onSearch(String value) {
    setState(() {
      _searchTerm = value;
      _currentPage = 1;
    });
    _loadStocks();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _importCsvData() async {
    final csvData = await CsvParser.pickAndParseCsv();
    if (csvData == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Importing Tools'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('Importing ${csvData.length} tools...'),
          ],
        ),
      ),
    );

    try {
      final tools = csvData.map((row) {
        final stock = int.tryParse(row['currentStock']?.toString() ?? '0') ?? 0;
        return {
          'toolName': row['toolName'] ?? '',
          'currentStock': stock,
          'minimumStock': 5,
          'maximumStock': stock + 50,
          'reorderLevel': 10,
          'reorderQuantity': 20,
          'unit': 'pieces',
          'location': 'Tool Room',
          'notes': row['remarks'] ?? '',
        };
      }).toList();

      final result = await ApiService.batchCreateToolStocks(tools);

      if (mounted) {
        Navigator.of(context).pop();
        
        if (result['success']) {
          final data = result['data'];
          final success = data['success'] ?? 0;
          final failed = data['failed'] ?? 0;
          _showSuccessSnackbar('Imported $success/${csvData.length} tools${failed > 0 ? " ($failed failed)" : ""}');
        } else {
          _showErrorSnackbar(result['message'] ?? 'Import failed');
        }
        
        _loadStocks();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorSnackbar('Import failed: $e');
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddStockDialog(ToolStock stock) {
    int quantity = 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stock: ${stock.toolName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Stock: ${stock.currentStock} ${stock.unit}'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Quantity to Add',
                border: OutlineInputBorder(),
                hintText: 'Enter quantity',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                quantity = int.tryParse(value) ?? 0;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (quantity > 0) {
                try {
                  await ApiService.addStock(stock.id, quantity);
                  _showSuccessSnackbar('Stock added successfully');
                  _loadStocks();
                } catch (e) {
                  _showErrorSnackbar('Failed to add stock: $e');
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRemoveStockDialog(ToolStock stock) {
    int quantity = 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Stock: ${stock.toolName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Stock: ${stock.currentStock} ${stock.unit}'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Quantity to Remove',
                border: OutlineInputBorder(),
                hintText: 'Enter quantity',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                quantity = int.tryParse(value) ?? 0;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (quantity > 0) {
                try {
                  await ApiService.removeStock(stock.id, quantity);
                  _showSuccessSnackbar('Stock removed successfully');
                  _loadStocks();
                } catch (e) {
                  _showErrorSnackbar('Failed to remove stock: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddToolDialog() {
    final toolNameController = TextEditingController();
    final atcPocketNoController = TextEditingController();
    final toolRoomNoController = TextEditingController();
    final currentStockController = TextEditingController();
    final minimumStockController = TextEditingController(text: '5');
    final maximumStockController = TextEditingController(text: '50');
    final reorderLevelController = TextEditingController(text: '10');
    final reorderQuantityController = TextEditingController(text: '20');
    final unitController = TextEditingController(text: 'pieces');
    final locationController = TextEditingController(text: 'Tool Room');
    final costPerUnitController = TextEditingController(text: '0');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Tool Stock'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: toolNameController,
                decoration: const InputDecoration(
                  labelText: 'Tool Name *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter tool name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: atcPocketNoController,
                decoration: const InputDecoration(
                  labelText: 'ATC Pocket No.',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., CCMT D6 D2 D4',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: toolRoomNoController,
                decoration: const InputDecoration(
                  labelText: 'Tool Room No.',
                  border: OutlineInputBorder(),
                  hintText: 'Optional',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: currentStockController,
                decoration: const InputDecoration(
                  labelText: 'Current Stock *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter quantity',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minimumStockController,
                      decoration: const InputDecoration(
                        labelText: 'Min Stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maximumStockController,
                      decoration: const InputDecoration(
                        labelText: 'Max Stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: reorderLevelController,
                      decoration: const InputDecoration(
                        labelText: 'Reorder Level',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: reorderQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Reorder Qty',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: costPerUnitController,
                      decoration: const InputDecoration(
                        labelText: 'Cost/Unit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Optional remarks',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Validation
              if (toolNameController.text.trim().isEmpty) {
                _showErrorSnackbar('Tool name is required');
                return;
              }
              
              if (currentStockController.text.trim().isEmpty) {
                _showErrorSnackbar('Current stock is required');
                return;
              }

              try {
                await ApiService.createToolStock(
                  toolName: toolNameController.text.trim(),
                  atcPocketNo: atcPocketNoController.text.trim(),
                  toolRoomNo: toolRoomNoController.text.trim(),
                  currentStock: int.parse(currentStockController.text) ?? 0,
                  minimumStock: int.parse(minimumStockController.text) ?? 5,
                  maximumStock: int.parse(maximumStockController.text) ?? 50,
                  reorderLevel: int.parse(reorderLevelController.text) ?? 10,
                  reorderQuantity: int.parse(reorderQuantityController.text) ?? 20,
                  unit: unitController.text.trim(),
                  location: locationController.text.trim(),
                  costPerUnit: double.parse(costPerUnitController.text) ?? 0,
                  notes: notesController.text.trim(),
                );
                _showSuccessSnackbar('Tool stock added successfully');
                _loadStocks();
              } catch (e) {
                _showErrorSnackbar('Failed to add tool stock: $e');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditToolDialog(ToolStock stock) {
    final toolNameController = TextEditingController(text: stock.toolName);
    final atcPocketNoController = TextEditingController(text: stock.atcPocketNo);
    final toolRoomNoController = TextEditingController(text: stock.toolRoomNo);
    final minimumStockController = TextEditingController(text: '${stock.minimumStock}');
    final maximumStockController = TextEditingController(text: '${stock.maximumStock}');
    final reorderLevelController = TextEditingController(text: '${stock.reorderLevel}');
    final reorderQuantityController = TextEditingController(text: '${stock.reorderQuantity}');
    final unitController = TextEditingController(text: stock.unit);
    final locationController = TextEditingController(text: stock.location);
    final costPerUnitController = TextEditingController(text: '${stock.costPerUnit}');
    final notesController = TextEditingController(text: stock.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tool Stock'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: toolNameController,
                decoration: const InputDecoration(
                  labelText: 'Tool Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: atcPocketNoController,
                decoration: const InputDecoration(
                  labelText: 'ATC Pocket No.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: toolRoomNoController,
                decoration: const InputDecoration(
                  labelText: 'Tool Room No.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minimumStockController,
                      decoration: const InputDecoration(
                        labelText: 'Min Stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maximumStockController,
                      decoration: const InputDecoration(
                        labelText: 'Max Stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: reorderLevelController,
                      decoration: const InputDecoration(
                        labelText: 'Reorder Level',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: reorderQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Reorder Qty',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: costPerUnitController,
                      decoration: const InputDecoration(
                        labelText: 'Cost/Unit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await ApiService.updateToolStock(
                  stock.id,
                  toolName: toolNameController.text.trim(),
                  atcPocketNo: atcPocketNoController.text.trim(),
                  toolRoomNo: toolRoomNoController.text.trim(),
                  minimumStock: int.parse(minimumStockController.text) ?? 5,
                  maximumStock: int.parse(maximumStockController.text) ?? 50,
                  reorderLevel: int.parse(reorderLevelController.text) ?? 10,
                  reorderQuantity: int.parse(reorderQuantityController.text) ?? 20,
                  unit: unitController.text.trim(),
                  location: locationController.text.trim(),
                  costPerUnit: double.parse(costPerUnitController.text) ?? 0,
                  notes: notesController.text.trim(),
                );
                _showSuccessSnackbar('Tool stock updated successfully');
                _loadStocks();
              } catch (e) {
                _showErrorSnackbar('Failed to update tool stock: $e');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(ToolStock stock) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tool Stock'),
        content: Text(
          'Are you sure you want to delete "${stock.toolName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await ApiService.deleteToolStock(stock.id);
                _showSuccessSnackbar('Tool stock deleted successfully');
                _loadStocks();
              } catch (e) {
                _showErrorSnackbar('Failed to delete tool stock: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (!_isLoading) _buildStatisticsBar(),
          SliverFillRemaining(
            child: _isLoading
                ? const Center(child: ModernLoadingIndicator())
                : _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddToolDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Tool'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.upload_file),
          onPressed: _importCsvData,
          tooltip: 'Import CSV Data',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tool Stock Management',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage and track tool inventory',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ModernSearchBar(
                    controller: _searchController,
                    hintText: 'Search tools...',
                    onChanged: _onSearch,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsBar() {
    return SliverToBoxAdapter(
      child: _statistics != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Items',
                      '${_statistics!.totalItems}',
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Critical',
                      '${_statistics!.criticalCount}',
                      AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Low Stock',
                      '${_statistics!.lowStockCount}',
                      AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_stocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storage_outlined,
              size: 80,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tool stocks found',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ModernButton(
              text: 'Refresh',
              icon: Icons.refresh,
              onPressed: _loadStocks,
              style: ModernButtonStyle.outline,
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimationLimiter(
            child: ListView.builder(
              itemCount: _stocks.length + 1,
              itemBuilder: (context, index) {
                if (index == _stocks.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentPage > 1)
                          ModernButton(
                            text: 'Previous',
                            icon: Icons.arrow_back,
                            onPressed: () {
                              setState(() => _currentPage--);
                              _loadStocks();
                            },
                            style: ModernButtonStyle.outline,
                          ),
                        const SizedBox(width: 12),
                        Text(
                          'Page $_currentPage of $_totalPages',
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(width: 12),
                        if (_currentPage < _totalPages)
                          ModernButton(
                            text: 'Next',
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              setState(() => _currentPage++);
                              _loadStocks();
                            },
                            style: ModernButtonStyle.outline,
                          ),
                      ],
                    ),
                  );
                }

                final stock = _stocks[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 400),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildStockCard(stock),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockCard(ToolStock stock) {
    Color statusColor;
    IconData statusIcon;
    
    switch (stock.status) {
      case 'out_of_stock':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
        break;
      case 'critical':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.warning;
        break;
      case 'low_stock':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.info;
        break;
      default:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
    }

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.toolName,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'ATC: ${stock.atcPocketNo}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (stock.toolRoomNo.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Room: ${stock.toolRoomNo}',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stock bars
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${stock.currentStock}/${stock.maximumStock} ${stock.unit}',
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: stock.getStockPercentage(),
                      backgroundColor: AppTheme.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Min: ${stock.minimumStock}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Reorder: ${stock.reorderLevel}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stock.getStatusLabel(),
                    style: AppTheme.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Updated by: ${stock.lastUpdatedByName}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ModernButton(
                text: 'Delete',
                icon: Icons.delete,
                onPressed: () => _showDeleteConfirmDialog(stock),
                style: ModernButtonStyle.outline,
              ),
              ModernButton(
                text: 'Edit',
                icon: Icons.edit,
                onPressed: () => _showEditToolDialog(stock),
                style: ModernButtonStyle.outline,
              ),
              ModernButton(
                text: 'Remove',
                icon: Icons.remove,
                onPressed: () => _showRemoveStockDialog(stock),
                style: ModernButtonStyle.outline,
              ),
              ModernButton(
                text: 'Add',
                icon: Icons.add,
                onPressed: () => _showAddStockDialog(stock),
                style: ModernButtonStyle.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}