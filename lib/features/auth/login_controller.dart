class LoginController {
  final Map<String, String> _userDatabase = {
    'admin': '123',
    'budi': 'budi2024',
    'siti': 'siti123',
    'dosen': 'admin_dosen',
  };


  bool login(String username, String password) {
    final String cleanUser = username.trim();
    final String cleanPass = password.trim(); 

    if (!_userDatabase.containsKey(cleanUser)) {
      return false; // Username tidak ditemukan
    }

    if (_userDatabase[cleanUser] == cleanPass) {
      return true; // Kredensial Valid
    }

    return false;
  }
}