import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data Onboarding 
  final List<Map<String, String>> _onboardingData = [
    {
      "image": "assets/images/pytorch_image.jpg", // Pastikan ekstensi file benar
      "title": "PyTorch Power",
      "desc": "Framework Deep Learning yang dinamis dan fleksibel untuk riset."
    },
    {
      "image": "assets/images/sklearn_image.png",
      "title": "Scikit-Learn Logic",
      "desc": "Library Machine Learning klasik yang efisien untuk analisis data."
    },
    {
      "image": "assets/images/tf_image.png",
      "title": "TensorFlow Tech",
      "desc": "Platform end-to-end open source untuk membangun model ML skala besar."
    },
  ];

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Menampilkan Gambar Aset
                        Image.asset(
                          _onboardingData[index]["image"]!,
                          height: 250,
                          errorBuilder: (ctx, err, stack) => 
                              const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          _onboardingData[index]["title"]!,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _onboardingData[index]["desc"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Indikator Halaman (Titik-titik)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 10,
                  width: _currentPage == index ? 20 : 10, // Lebar berubah jika aktif
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.indigo : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Tombol Navigasi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _currentPage == _onboardingData.length - 1
                      ? _finishOnboarding
                      : () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                  child: Text(
                    _currentPage == _onboardingData.length - 1 ? "Mulai Sekarang" : "Lanjut",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}