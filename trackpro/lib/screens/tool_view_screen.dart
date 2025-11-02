import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ToolViewScreen extends StatefulWidget {
  final String toolName;

  const ToolViewScreen({super.key, required this.toolName});

  @override
  State<ToolViewScreen> createState() => _ToolViewScreenState();
}

class _ToolViewScreenState extends State<ToolViewScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _toolData = [];
  Map<String, dynamic>? _metadata;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadToolData();
  }

  Future<void> _loadToolData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getToolListByName(widget.toolName);
      final data = response['data'] ?? {};
      final sheets = data['sheets'] ?? [];
      final firstSheet = sheets.isNotEmpty ? sheets[0] : {};
      
      setState(() {
        _toolData = List<Map<String, dynamic>>.from(firstSheet['toolData'] ?? []);
        _metadata = data['totals'] ?? {
          'totalTools': 0,
          'totalHoles': 0,
          'totalCuttingLength': 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredData {
    if (_searchQuery.isEmpty) return _toolData;
    return _toolData.where((tool) {
      final query = _searchQuery.toLowerCase();
      return tool['toolName'].toString().toLowerCase().contains(query) ||
             tool['holderName'].toString().toLowerCase().contains(query) ||
             tool['atcPocketNo'].toString().toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.toolName, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadToolData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text('Error: $_error', style: TextStyle(color: Colors.red.shade700)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadToolData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSummaryCards(),
                    _buildSearchBar(),
                    Expanded(child: _buildModernTable()),
                  ],
                ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Tools', '${_metadata?['totalTools'] ?? 0}', Icons.build, Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Holes', '${_metadata?['totalHoles'] ?? 0}', Icons.circle_outlined, Colors.orange)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Length', '${_metadata?['totalCuttingLength'] ?? 0}', Icons.straighten, Colors.green)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search tools...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchQuery = ''))
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildModernTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text('${_filteredData.length} Tools', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                  dataRowHeight: 56,
                  columns: const [
                    DataColumn(label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('POCKET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('TOOL NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('HOLDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('ROOM NO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('HOLES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('LENGTH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('REMARKS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  rows: _filteredData.asMap().entries.map((entry) {
                    final tool = entry.value;
                    final isEven = entry.key % 2 == 0;
                    return DataRow(
                      color: MaterialStateProperty.all(isEven ? Colors.white : Colors.grey.shade50),
                      cells: [
                        DataCell(Text('${tool['slNo'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text('${tool['atcPocketNo'] ?? ''}')),
                        DataCell(Text('${tool['toolName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Text('${tool['holderName'] ?? ''}')),
                        DataCell(Text('${tool['toolRoomNo'] ?? ''}')),
                        DataCell(Text('${tool['noOfHolesInComponent'] ?? ''}', style: TextStyle(color: Colors.orange.shade700))),
                        DataCell(Text('${tool['cuttingLength'] ?? ''}', style: TextStyle(color: Colors.green.shade700))),
                        DataCell(Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text('${tool['remarks'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
