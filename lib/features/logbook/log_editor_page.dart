import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final dynamic currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    
    // Ambil status privasi dari log yang sudah ada (jika sedang edit)
    _isPublic = widget.log?.isPublic ?? false;
    
    // Listener to update markdown preview automatically
    _descController.addListener(() {
      setState(() {});
    });
  }

  void _save() {
    if (widget.log == null) {
      // Add new log
      widget.controller.addLog(
        _titleController.text,
        _descController.text,
        LogCategory.other, // Default category
        widget.currentUser['uid'],
        widget.currentUser['teamId'],
        _isPublic, // Tambahan parameter isPublic
      );
    } else {
      // Edit existing log
      widget.controller.editLog(
        widget.log!,
        _titleController.text,
        _descController.text,
        widget.log!.category, 
        _isPublic, // Tambahan parameter isPublic
      );
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // Clean up controllers
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.save), onPressed: _save)
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Editor
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Judul"),
                  ),
                  const SizedBox(height: 10),
                  
                  // Tambahan Switch Toggle untuk Privasi
                  SwitchListTile(
                    title: const Text("Buat Publik"),
                    subtitle: const Text("Anggota tim dapat melihat catatan ini"),
                    value: _isPublic,
                    contentPadding: EdgeInsets.zero, // Biar sejajar dengan textfield
                    onChanged: (bool value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: "Tulis laporan dengan format Markdown...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab 2: Markdown Preview
            Markdown(data: _descController.text),
          ],
        ),
      ),
    );
  }
}