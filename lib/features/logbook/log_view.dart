import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart';

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

  @override
  void initState() {
    super.initState();

    controller = LogController();
    controller.init(widget.currentUser['role'], widget.currentUser['uid']).then((_) {
      controller.loadLogs(widget.currentUser['teamId']);
    });

    _checkConnection();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOfflineNow = results.contains(ConnectivityResult.none);
      
      setState(() {
        _isOffline = isOfflineNow;
      });

      if (!isOfflineNow) {
        controller.syncPendingLogs(widget.currentUser['teamId']);
        
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => controller.searchLog(value),
                    decoration: InputDecoration(
                      hintText: "Cari berdasarkan judul...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<LogCategory?>(
                  valueListenable: controller.selectedCategoryFilter,
                  builder: (context, selectedCategory, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<LogCategory?>(
                          value: selectedCategory,
                          hint: const Text("Semua"),
                          icon: const Icon(Icons.filter_list),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text("Semua"),
                            ),
                            ...LogCategory.values.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(getCategoryName(category)),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            controller.filterByCategory(value);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: controller.filteredLogs,
              builder: (context, logs, _) {
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.note_alt_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Belum ada catatan.\nMulai catat kemajuan proyek Anda!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _goToEditor(),
                          icon: const Icon(Icons.add),
                          label: const Text("Buat Catatan Pertama"),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final bool isOwner = log.authorId == widget.currentUser['uid'];
                    final Color cardColor = categoryColors[log.category] ?? Colors.grey;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: cardColor, width: 6),
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            log.id != null
                                ? Icons.cloud_done
                                : Icons.cloud_upload_outlined,
                            color: log.id != null ? Colors.green : Colors.orange,
                          ),
                          title: Text(log.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cardColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      getCategoryName(log.category),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: cardColor.withOpacity(0.8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatTimestamp(log.date),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                log.isPublic ? Icons.public : Icons.lock,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
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
    super.dispose();
  }
}