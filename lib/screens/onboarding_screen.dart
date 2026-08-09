import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_model.dart';
import '../screens/home_screen.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboard', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌿 Background Gradient
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Color(0xfffde8bd).withOpacity(0.3),
              BlendMode.srcATop,
            ),
            child: Image.asset(
              'assets/images/background.jpg',
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onBoardData.length,
                  onPageChanged: (index) {
                    setState(() => currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final item = onBoardData[index];

                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /// ✨ Animated Image
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            child: Image.asset(item.image, height: 240),
                          ),

                          const SizedBox(height: 30),

                          /// 🌿 Glass Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  item.title,
                                  textAlign: TextAlign.center,

                                  style: const TextStyle(
                                    fontFamily: 'Roya',
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff3c2201),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.description,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    fontFamily: 'Roya',
                                    fontSize: 18,
                                    height: 1.6,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              /// 🔘 Dots Indicator (Professional)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onBoardData.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentIndex == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          currentIndex == index
                              ? Color(0xff9c7e44)
                              : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// 🎯 Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    /// Skip
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text(
                        'رد کردن',
                        style: TextStyle(
                          fontFamily: 'Roya',
                          fontSize: 16,
                          color: Colors.brown,
                        ),
                      ),
                    ),

                    const Spacer(),

                    /// Next / Start Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 6,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        backgroundColor: const Color(0xff9c7e44),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        if (currentIndex == onBoardData.length - 1) {
                          _finishOnboarding();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        currentIndex == onBoardData.length - 1
                            ? 'شروع ✨'
                            : 'بعدی',
                        style: const TextStyle(
                          fontFamily: 'Roya',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }
}
