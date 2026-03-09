import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  // Enkapsulasi data
  int _counter = 0;
  int _step = 1;
  List<String> _history = [];
  
  // simpan user login
  String? _currentUser; 

  // Getter
  int get value => _counter;
  int get step => _step;
  List<String> get history => _history;

  void setUser(String username) {
    _currentUser = username;
  }

  /// Memuat data yang sedang login
  Future<void> loadData() async {
    // Jika user belum diset tidak load apapun
    if (_currentUser == null) return; 

    final prefs = await SharedPreferences.getInstance();
    
    //Gunakan username sebagai bagian dari Key 
    String keyCounter = 'counter_$_currentUser';
    String keyHistory = 'history_$_currentUser';
    
    _counter = prefs.getInt(keyCounter) ?? 0;
    _history = prefs.getStringList(keyHistory) ?? [];
  }

  /// Menyimpan data ke memori HP (Save)
  Future<void> _saveToStorage() async {
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    
    // Gunakan key yang sama dengan saat load
    String keyCounter = 'counter_$_currentUser';
    String keyHistory = 'history_$_currentUser';
    
    await prefs.setInt(keyCounter, _counter);
    await prefs.setStringList(keyHistory, _history);
  }

  void updateStep(int newStep) {
    _step = newStep;
  }

  void _logActivity(String activity) {
    DateTime now = DateTime.now();
    String timestamp = "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}";
    
    _history.insert(0, "[$timestamp] $activity");

    // Limit riwayat maksimal 5 item 
    if (_history.length > 5) {
      _history.removeLast();
    }
  }

  void increment() {
    _counter += _step;
    _logActivity("Menambah $_step");
    _saveToStorage(); // Simpan otomatis
  }

  void decrement() {
    if (_counter >= _step) {
      _counter -= _step;
    } else {
      _counter = 0;
    }
    _logActivity("Mengurang $_step");
    _saveToStorage();
  }

  void reset() {
    _counter = 0;
    _history.clear(); 
    _logActivity("Reset Counter");
    _saveToStorage(); 
  }
}