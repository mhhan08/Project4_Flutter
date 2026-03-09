import 'dart:async'; // Diperlukan untuk Timer
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';
import 'package:logbook_app_001/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Controller Logic & Input
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // State Variables
  bool _isObscure = true;         // Untuk fitur Show/Hide Password
  int _failedAttempts = 0;        // Menghitung jumlah gagal
  bool _isLocked = false;         // Status apakah tombol disable
  int _countdown = 0;             // Hitungan mundur 10 detik
  Timer? _timer;                  // Objek Timer

  // Membersihkan memori saat widget dihancurkan
  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Logika Utama Login
  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    // Validasi Input Kosong
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username dan Password tidak boleh kosong!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Cek Kredensial via Controller
    bool isSuccess = _controller.login(user, pass);

    if (isSuccess) {
      // Reset state jika berhasil dan pindah halaman
      setState(() => _failedAttempts = 0);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LogView()),
      );
    } else {
      // 3. Logika Gagal Login
      setState(() {
        _failedAttempts++;
      });

      // Cek apakah sudah 3x gagal
      if (_failedAttempts >= 3) {
        _startLockout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Gagal! Sisa percobaan: ${3 - _failedAttempts}"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // mematikan tombol selama 10 detik
  void _startLockout() {
    setState(() {
      _isLocked = true;
      _countdown = 10;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terlalu banyak percobaan. Tunggu 10 detik."),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
      ),
    );

    // Timer berjalan setiap 1 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        // Waktu habis, reset status kunci
        timer.cancel();
        setState(() {
          _isLocked = false;
          _failedAttempts = 0; // Reset counter gagal (opsional, tergantung kebijakan)
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input Username
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            
            // Input Password dengan Show/Hide
            TextField(
              controller: _passController,
              obscureText: _isObscure, // Mengontrol visibilitas teks
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                // Tombol Mata
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure; // Toggle status
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Login
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                // Jika _isLocked true, onPressed menjadi null (tombol mati)
                onPressed: _isLocked ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _isLocked ? "Tunggu ($_countdown dtk)" : "Masuk",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}