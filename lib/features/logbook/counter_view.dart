import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'counter_controller.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart'; 

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  late TextEditingController _stepInputController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _stepInputController = TextEditingController(text: "1");
    
    // Setup User & Load Data
    _controller.setUser(widget.username);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _controller.loadData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String get _greetingMessage {
    var hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  void dispose() {
    _stepInputController.dispose();
    super.dispose();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const OnboardingView()),
                (route) => false,
              );
            },
            child: const Text("Ya", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Data"),
        content: const Text("Yakin ingin menghapus semua hitungan dan history?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              setState(() => _controller.reset()); // Eksekusi Reset
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("LogBook App", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // ucapan welcome
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$_greetingMessage, ${widget.username}!", 
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold, 
                        color: Colors.indigo
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text("Total Tersimpan:", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  
                  Text(
                    '${_controller.value}',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _stepInputController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      int? val = int.tryParse(value);
                      if (val != null && val > 0) _controller.updateStep(val);
                    },
                    decoration: const InputDecoration(
                      labelText: "Input Step",
                      prefixIcon: Icon(Icons.tune),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("History (Maks 5):", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  
                  ListView.builder(
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _controller.history.length,
                    itemBuilder: (context, index) {
                      final String log = _controller.history[index];
                      
                      Color itemColor = Colors.black87; 
                      IconData itemIcon = Icons.info;

                      if (log.contains("Menambah")) {
                        itemColor = Colors.green;
                        itemIcon = Icons.add_circle;
                      } else if (log.contains("Mengurang")) {
                        itemColor = Colors.red;
                        itemIcon = Icons.remove_circle;
                      } else if (log.contains("Reset")) {
                        itemColor = Colors.orange;
                        itemIcon = Icons.refresh;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: itemColor.withOpacity(0.5)), 
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(itemIcon, size: 18, color: itemColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                log, 
                                style: TextStyle(
                                  fontSize: 13, 
                                  color: itemColor, 
                                  fontWeight: FontWeight.w500
                                )
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 80), 
                ],
              ),
            ),
          ),
      
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tombol Reset memanggil _handleReset 
          FloatingActionButton(
            heroTag: "rst",
            mini: true,
            backgroundColor: Colors.red.shade100,
            foregroundColor: Colors.red,
            onPressed: _handleReset, 
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: "min",
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            onPressed: () => setState(() => _controller.decrement()),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: "plus",
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            onPressed: () => setState(() => _controller.increment()),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}