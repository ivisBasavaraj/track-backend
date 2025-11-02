// File: lib/screens/tool_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tool_list_model.dart';
import '../services/tools_service.dart';

class ToolListScreen extends StatefulWidget {
  const ToolListScreen({super.key});

  @override
  State<ToolListScreen> createState() => _ToolListScreenState();
}

class _ToolListScreenState extends State<ToolListScreen> {
  final ToolsService _toolsService = ToolsService();
  List<ToolList> _toolLists = [];
  bool _isLoading = true;
  String _searchTerm = '';
  final int _currentPage = 1;
  final int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadToolLists();
  }

  Future<void> _loadToolLists() async {
    setState(() => _isLoading = true);
    try {
      final toolLists = await _toolsService.getAllToolLists(
        page: _currentPage,
        limit: 10,
      );
      setState(() => _toolLists = toolLists);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tool lists: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<ToolList> get _filteredToolLists {
    if (_searchTerm.isEmpty) {
      return _toolLists;
    }
    return _toolLists
        .where((tool) =>
            tool.toolName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
            tool.uploaderName.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();
  }

  Future<void> _deleteToolList(String id, String toolName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tool List'),
        content: Text(
          'Are you sure you want to delete "$toolName"? This action cannot be undone.',
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
        await _toolsService.deleteToolList(id);
        await _loadToolLists();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tool list deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting tool list: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tool Lists',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tool lists...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchTerm.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => _searchTerm = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() => _searchTerm = value);
                    },
                  ),
                ),

                // Tool lists
                Expanded(
                  child: _filteredToolLists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchTerm.isEmpty
                                    ? 'No tool lists found'
                                    : 'No results for "$_searchTerm"',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadToolLists,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredToolLists.length,
                            itemBuilder: (context, index) {
                              final toolList = _filteredToolLists[index];
                              return _buildToolListCard(toolList);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildToolListCard(ToolList toolList) {
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(
          toolList.toolName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Tools: ${toolList.totalTools} | Holes: ${toolList.totalHoles} | Length: ${toolList.totalCuttingLength.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Uploaded by: ${toolList.uploaderName}',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormatter.format(toolList.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Tool Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                // Scrollable table
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('SL NO', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Pocket', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tool Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Holder', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Room', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Holes', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Length', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: toolList.toolData
                        .map(
                          (tool) => DataRow(
                            cells: [
                              DataCell(Text(tool.slNo.toString())),
                              DataCell(Text(tool.atcPocketNo)),
                              DataCell(Text(tool.toolName)),
                              DataCell(Text(tool.holderName)),
                              DataCell(Text(tool.toolRoomNo)),
                              DataCell(Text(tool.noOfHolesInComponent.toString())),
                              DataCell(Text(tool.cuttingLength.toStringAsFixed(2))),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
                // Remarks section if present
                if (toolList.toolData.any((tool) => tool.remarks.isNotEmpty)) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Remarks:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: toolList.toolData
                          .where((tool) => tool.remarks.isNotEmpty)
                          .map(
                            (tool) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SL ${tool.slNo}: ',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  Expanded(
                                    child: Text(
                                      tool.remarks,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // View details functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('View details')),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _deleteToolList(toolList.id, toolList.toolName),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}