// File: lib/screens/modern_tool_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/api_service.dart';
import '../models/tool_list_model.dart';
import '../ui/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_search.dart';
import '../widgets/modern_loading.dart';
import '../widgets/modern_dashboard.dart';
import '../widgets/page_transitions.dart';

class ModernToolViewScreen extends StatefulWidget {
  final ToolList toolList;

  const ModernToolViewScreen({super.key, required this.toolList});

  @override
  State<ModernToolViewScreen> createState() => _ModernToolViewScreenState();
}

class _ModernToolViewScreenState extends State<ModernToolViewScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Data state
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _toolData = [];
  List<Map<String, dynamic>> _filteredToolData = [];
  Map<String, dynamic>? _metadata;
  String _searchQuery = '';
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();

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

    _loadToolData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadToolData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getToolListByName(widget.toolList.toolName);
      final data = response['data'] ?? {};
      final sheets = data['sheets'] ?? [];
      final firstSheet = sheets.isNotEmpty ? sheets[0] : {};
      
      setState(() {
        _toolData = List<Map<String, dynamic>>.from(firstSheet['toolData'] ?? []);
        _filteredToolData = _toolData;
        _metadata = data['totals'] ?? {
          'totalTools': 0,
          'totalHoles': 0,
          'totalCuttingLength': 0,
        };
        _isLoading = false;
      });

      // Start animations
      _slideController.forward();
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTools(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredToolData = _toolData;
      } else {
        _filteredToolData = _toolData.where((tool) {
          return tool.values.any((value) => 
            value.toString().toLowerCase().contains(query.toLowerCase())
          );
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingText: "Loading tool data...",
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  _buildModernAppBar(),
                  if (_error != null)
                    _buildErrorState()
                  else if (_isLoading)
                    _buildLoadingState()
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsSection(),
                            const SizedBox(height: 24),
                            _buildSearchSection(),
                            const SizedBox(height: 16),
                            _buildToolsTable(),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
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
                  widget.toolList.toolName,
                  style: AppTheme.displaySmall,
                ),
                const SizedBox(height: 4),
                if (widget.toolList.toolName.isNotEmpty)
                  Text(
                    widget.toolList.toolName,
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

  Widget _buildStatsSection() {
    if (_metadata == null) return const SizedBox.shrink();

    final stats = [
      DashboardStat(
        title: 'Total Tools',
        value: _metadata!['totalTools'] ?? 0,
        icon: Icons.build_circle_outlined,
        color: AppTheme.primaryColor,
      ),
      DashboardStat(
        title: 'Total Holes',
        value: _metadata!['totalHoles'] ?? 0,
        icon: Icons.radio_button_unchecked_outlined,
        color: AppTheme.secondaryColor,
      ),
      DashboardStat(
        title: 'Cutting Length',
        value: _metadata!['totalCuttingLength'] ?? 0.0,
        icon: Icons.straighten_outlined,
        color: AppTheme.warningColor,
        isDecimal: true,
      ),
      DashboardStat(
        title: 'Filtered Results',
        value: _filteredToolData.length,
        icon: Icons.filter_list_outlined,
        color: AppTheme.infoColor,
      ),
    ];

    return ModernDashboardStats(
      stats: stats,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    );
  }

  Widget _buildSearchSection() {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Search Tools',
                style: AppTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ModernSearchBar(
            controller: _searchController,
            hintText: 'Search by tool name, holder, room, etc...',
            onChanged: _filterTools,
            showClearButton: true,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.infoColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Found ${_filteredToolData.length} results for "$_searchQuery"',
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolsTable() {
    if (_filteredToolData.isEmpty) {
      return _buildEmptyState();
    }

    return ModernCard(
      title: 'Tool Details',
      subtitle: '${_filteredToolData.length} tools displayed',
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.table_view_rounded,
          color: AppTheme.successColor,
          size: 20,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                _buildTableHeader(),
                const SizedBox(height: 8),
                AnimationLimiter(
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: AppDurations.fast,
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 20.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: _filteredToolData.take(50).map((tool) {
                        final index = _filteredToolData.indexOf(tool);
                        return _buildTableRow(tool, index);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_filteredToolData.length > 50) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Showing first 50 results. Use search to narrow down.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    if (_toolData.isEmpty) return const SizedBox.shrink();
    
    final headers = _toolData.first.keys.toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: headers.map((header) {
          return SizedBox(
            width: 120,
            child: Text(
              header.toUpperCase(),
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.left,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> tool, int index) {
    final isEven = index % 2 == 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEven ? AppTheme.backgroundColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: tool.values.map((value) {
          return SizedBox(
            width: 120,
            child: Text(
              value?.toString() ?? '',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ModernCard(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              _searchQuery.isNotEmpty 
                ? Icons.search_off_rounded 
                : Icons.inventory_2_outlined,
              color: AppTheme.textTertiary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                ? 'No Tools Match Your Search'
                : 'No Tools Available',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms or clear the search to see all tools'
                : 'This tool list appears to be empty',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _filterTools('');
                },
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('Clear Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: ModernCard(
          child: Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.errorColor,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to Load Tools',
                  style: AppTheme.headlineMedium.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'An unexpected error occurred',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadToolData,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ModernLoadingIndicator(
              size: 48,
              style: LoadingStyle.pulse,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading tool data...',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}