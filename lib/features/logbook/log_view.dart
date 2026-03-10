import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';
import 'dart:async';

class LogView extends StatefulWidget {
  final dynamic currentUser;

  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController controller;

  bool _isOffline = false;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller = LogController();
    controller.init(widget.currentUser['role'], widget.currentUser['uid']).then((_) {
      controller.loadLogs(widget.currentUser['teamId']);
    });

    _checkConnection();

    // TASK 4: Background Sync Listener
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOfflineNow = results.contains(ConnectivityResult.none);
      
      setState(() {
        _isOffline = isOfflineNow;
      });

      // Jika status berubah dari offline menjadi ONLINE
      if (!isOfflineNow) {
        // Picu sinkronisasi latar belakang
        controller.syncPendingLogs(widget.currentUser['teamId']);
        
        // Berikan feedback visual ke pengguna
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Internet pulih. Sinkronisasi data di latar belakang..."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    setState(() {
      _isOffline = connectivityResult.contains(ConnectivityResult.none);
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginView(),
                ),
                (route) => false,
              );
            },
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(LogModel log) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Catatan"),
        content: Text("Yakin ingin menghapus '${log.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String formatTimestamp(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return "Baru saja";
      if (difference.inMinutes < 60) return "${difference.inMinutes} menit lalu";
      if (difference.inHours < 24) return "${difference.inHours} jam lalu";
      if (difference.inDays < 7) return "${difference.inDays} hari lalu";

      return DateFormat("dd MMM yyyy", "id_ID").format(date);
    } catch (e) {
      return isoDate;
    }
  }

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook - ${widget.currentUser['username']}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade300,
              padding: const EdgeInsets.all(8),
              child: const Text(
                "Offline Mode",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => controller.searchLog(value),
              decoration: InputDecoration(
                hintText: "Cari berdasarkan judul...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: controller.filteredLogs,
              builder: (context, logs, _) {
                if (logs.isEmpty) {
                  return const Center(child: Text("Tidak ada data"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];

                    final bool isOwner =
                        log.authorId == widget.currentUser['uid'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          log.id != null
                              ? Icons.cloud_done
                              : Icons.cloud_upload_outlined,
                          color:
                              log.id != null ? Colors.green : Colors.orange,
                        ),
                        title: Text(log.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.description),
                            const SizedBox(height: 4),
                            Text(
                              formatTimestamp(log.date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                         trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Indikator visual apakah log ini publik atau privat
                            if (log.isPublic) 
                              const Icon(Icons.public, size: 16, color: Colors.grey),
                            if (!log.isPublic) 
                              const Icon(Icons.lock, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            
                            // TASK 5: Kedaulatan Mutlak - HANYA OWNER YANG BISA EDIT/DELETE
                            if (isOwner)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _goToEditor(log: log, index: index),
                              ),
                            if (isOwner)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final ok = await _confirmDelete(log);
                                  if (ok == true) {
                                    await controller.removeLog(index);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(), 
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _searchController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}