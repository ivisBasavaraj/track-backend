import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/tool_list_model.dart';
import '../services/tools_service.dart';

class MasterToolManagementScreen extends StatefulWidget {
  const MasterToolManagementScreen({Key? key}) : super(key: key);

  @override
  State<MasterToolManagementScreen> createState() => _MasterToolManagementScreenState();
}

class _MasterToolManagementScreenState extends State<MasterToolManagementScreen> {
  final _toolsService = ToolsService();
  List<ToolList> _toolLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    setState(() => _isLoading = true);
    try {
      final tools = await _toolsService.getAllToolLists(limit: 100);
      setState(() {
        _toolLists = tools;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading tools: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _uploadCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final toolNameController = TextEditingController();

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upload CSV'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('File: ${file.name}'),
              const SizedBox(height: 16),
              TextField(
                controller: toolNameController,
                decoration: const InputDecoration(
                  labelText: 'Tool List Name *',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Upload'),
            ),
          ],
        ),
      );

      if (confirmed != true || toolNameController.text.trim().isEmpty) return;

      setState(() => _isLoading = true);

      await _toolsService.uploadToolList(
        toolName: toolNameController.text.trim(),
        csvFileBytes: file.bytes,
        csvFilePath: file.path,
        overwrite: false,
      );

      _showSuccess('CSV uploaded and stored in database');
      _loadTools();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Upload failed: $e');
    }
  }

  void _viewToolDetails(ToolList toolList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ToolDetailsScreen(
          toolList: toolList,
          onUpdate: _loadTools,
        ),
      ),
    );
  }

  void _deleteToolList(ToolList toolList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tool List'),
        content: Text('Delete "${toolList.toolName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _toolsService.deleteToolList(toolList.id);
                _showSuccess('Tool list deleted');
                _loadTools();
              } catch (e) {
                _showError('Error: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Tool Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _uploadCSV,
            tooltip: 'Upload CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTools,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _toolLists.isEmpty
              ? const Center(child: Text('No tool lists found. Upload a CSV to get started.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _toolLists.length,
                  itemBuilder: (context, index) {
                    final toolList = _toolLists[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(toolList.toolName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tools: ${toolList.totalTools} | Holes: ${toolList.totalHoles}'),
                            Text('Uploaded by: ${toolList.uploaderName}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () => _viewToolDetails(toolList),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteToolList(toolList),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class ToolDetailsScreen extends StatefulWidget {
  final ToolList toolList;
  final VoidCallback onUpdate;

  const ToolDetailsScreen({Key? key, required this.toolList, required this.onUpdate}) : super(key: key);

  @override
  State<ToolDetailsScreen> createState() => _ToolDetailsScreenState();
}

class _ToolDetailsScreenState extends State<ToolDetailsScreen> {
  final _toolsService = ToolsService();
  late List<Tool> _tools;

  @override
  void initState() {
    super.initState();
    _tools = List.from(widget.toolList.toolData);
  }

  void _addTool() {
    showDialog(
      context: context,
      builder: (context) => _ToolFormDialog(
        onSave: (tool) {
          setState(() => _tools.add(tool));
          _saveToDB();
        },
      ),
    );
  }

  void _editTool(int index) {
    showDialog(
      context: context,
      builder: (context) => _ToolFormDialog(
        tool: _tools[index],
        onSave: (tool) {
          setState(() => _tools[index] = tool);
          _saveToDB();
        },
      ),
    );
  }

  void _deleteTool(int index) {
    setState(() => _tools.removeAt(index));
    _saveToDB();
  }

  Future<void> _saveToDB() async {
    try {
      final result = await _toolsService.updateToolList(
        id: widget.toolList.id,
        toolName: widget.toolList.toolName,
        toolData: _tools.map((t) => t.toMap()).toList(),
      );
      
      if (result != null) {
        widget.onUpdate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to database'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Update returned null');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.toolList.toolName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addTool,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tools.length,
        itemBuilder: (context, index) {
          final tool = _tools[index];
          return Card(
            child: ListTile(
              title: Text('${tool.slNo}. ${tool.toolName}'),
              subtitle: Text('Holder: ${tool.holderName} | Life: ${tool.toolLifeTime}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editTool(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTool(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToolFormDialog extends StatefulWidget {
  final Tool? tool;
  final Function(Tool) onSave;

  const _ToolFormDialog({this.tool, required this.onSave});

  @override
  State<_ToolFormDialog> createState() => _ToolFormDialogState();
}

class _ToolFormDialogState extends State<_ToolFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _slNoController;
  late TextEditingController _atcPocketController;
  late TextEditingController _toolNameController;
  late TextEditingController _holderNameController;
  late TextEditingController _toolRoomController;
  late TextEditingController _holesController;
  late TextEditingController _cuttingLengthController;
  late TextEditingController _remarksController;
  late TextEditingController _toolLifeTimeController;

  @override
  void initState() {
    super.initState();
    _slNoController = TextEditingController(text: widget.tool?.slNo.toString() ?? '');
    _atcPocketController = TextEditingController(text: widget.tool?.atcPocketNo ?? '');
    _toolNameController = TextEditingController(text: widget.tool?.toolName ?? '');
    _holderNameController = TextEditingController(text: widget.tool?.holderName ?? '');
    _toolRoomController = TextEditingController(text: widget.tool?.toolRoomNo ?? '');
    _holesController = TextEditingController(text: widget.tool?.noOfHolesInComponent.toString() ?? '0');
    _cuttingLengthController = TextEditingController(text: widget.tool?.cuttingLength.toString() ?? '0');
    _remarksController = TextEditingController(text: widget.tool?.remarks ?? '');
    _toolLifeTimeController = TextEditingController(text: widget.tool?.toolLifeTime.toString() ?? '0');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tool == null ? 'Add Tool' : 'Edit Tool'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _slNoController,
                decoration: const InputDecoration(labelText: 'SL No *'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _atcPocketController,
                decoration: const InputDecoration(labelText: 'ATC Pocket No'),
              ),
              TextFormField(
                controller: _toolNameController,
                decoration: const InputDecoration(labelText: 'Tool Name *'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _holderNameController,
                decoration: const InputDecoration(labelText: 'Holder Name'),
              ),
              TextFormField(
                controller: _toolRoomController,
                decoration: const InputDecoration(labelText: 'Tool Room No'),
              ),
              TextFormField(
                controller: _holesController,
                decoration: const InputDecoration(labelText: 'No of Holes'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _cuttingLengthController,
                decoration: const InputDecoration(labelText: 'Cutting Length'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
              TextFormField(
                controller: _toolLifeTimeController,
                decoration: const InputDecoration(labelText: 'Tool Life Time *'),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(Tool(
                slNo: int.parse(_slNoController.text),
                atcPocketNo: _atcPocketController.text,
                toolName: _toolNameController.text,
                holderName: _holderNameController.text,
                toolRoomNo: _toolRoomController.text,
                noOfHolesInComponent: int.tryParse(_holesController.text) ?? 0,
                cuttingLength: double.tryParse(_cuttingLengthController.text) ?? 0,
                remarks: _remarksController.text,
                toolLifeTime: int.tryParse(_toolLifeTimeController.text) ?? 0,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
