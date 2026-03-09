import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'models/log_model.dart';
import 'log_controller.dart';

class LogView extends StatefulWidget {
  const LogView({Key? key}) : super(key: key);

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController controller;
  bool _isOffline = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = LogController();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivity == ConnectivityResult.none;
    });
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingView()),
      (route) => false,
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
      if (difference.inMinutes < 60) return "${difference.inMinutes} menit yang lalu";
      if (difference.inHours < 24) return "${difference.inHours} jam yang lalu";
      if (difference.inDays < 7) return "${difference.inDays} hari yang lalu";
      return DateFormat("dd MMM yyyy", "id_ID").format(date);
    } catch (e) {
      return isoDate;
    }
  }

  void _showAddDialog() {
    _titleController.clear();
    _descController.clear();
    LogCategory selectedCategory = LogCategory.pekerjaan;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Tambah Catatan"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: "Judul"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(hintText: "Deskripsi"),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<LogCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: "Kategori"),
                  items: LogCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(getCategoryName(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() {
                        selectedCategory = value;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty) return;
                  await controller.addLog(
                    _titleController.text,
                    _descController.text,
                    selectedCategory,
                  );
                  Navigator.pop(context);
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditDialog(LogModel log) {
    _titleController.text = log.title;
    _descController.text = log.description;
    LogCategory selectedCategory = log.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Edit Catatan"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: "Judul"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(hintText: "Deskripsi"),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<LogCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: "Kategori"),
                  items: LogCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(getCategoryName(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() {
                        selectedCategory = value;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty) return;
                  await controller.editLog(
                    log,
                    _titleController.text,
                    _descController.text,
                    selectedCategory,
                  );
                  Navigator.pop(context);
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logbook"),
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

          ValueListenableBuilder<LogCategory?>(
            valueListenable: controller.selectedCategoryFilter,
            builder: (context, selectedCat, _) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text("Semua"),
                      selected: selectedCat == null,
                      onSelected: (selected) {
                        if (selected) controller.filterByCategory(null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...LogCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(getCategoryName(cat)),
                          selected: selectedCat == cat,
                          onSelected: (selected) {
                            controller.filterByCategory(selected ? cat : null);
                          },
                          selectedColor: categoryColors[cat],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }
          ),

          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: controller.isLoading,
              builder: (context, loading, _) {
                if (loading) return const Center(child: CircularProgressIndicator());

                return ValueListenableBuilder<List<LogModel>>(
                  valueListenable: controller.filteredLogs,
                  builder: (context, logs, _) {
                    if (logs.isEmpty) return const Center(child: Text("Tidak ada data"));

                    return RefreshIndicator(
                      onRefresh: controller.loadFromDisk,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return Dismissible(
                            key: ValueKey(log.id?.toHexString() ?? UniqueKey().toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              final ok = await _confirmDelete(log);
                              if (ok == true) {
                                await controller.removeLog(log);
                              }
                              return ok;
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(log.title)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: categoryColors[log.category] ?? Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        getCategoryName(log.category),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(log.description),
                                    const SizedBox(height: 6),
                                    Text(
                                      formatTimestamp(log.date),
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEditDialog(log),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final ok = await _confirmDelete(log);
                                        if (ok == true) {
                                          await controller.removeLog(log);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}