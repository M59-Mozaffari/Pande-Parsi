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

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentIndex == onBoardData.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              const Color(0xff3c2201).withOpacity(.18),
              BlendMode.srcATop,
            ),
            child: Image.asset(
              'assets/images/background.jpg',
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 700;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
                      child: Row(
                        children: [
                          Text(
                            '${currentIndex + 1} / ${onBoardData.length}',
                            style: const TextStyle(
                              fontFamily: 'Roya',
                              fontSize: 16,
                              color: Color(0xff3c2201),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _finishOnboarding,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xff3c2201),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            child: const Text(
                              'رد کردن',
                              style: TextStyle(
                                fontFamily: 'Roya',
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: onBoardData.length,
                        onPageChanged: (index) {
                          setState(() => currentIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return _OnboardingPage(
                            item: onBoardData[index],
                            compact: compact,
                          );
                        },
                      ),
                    ),
                    _PageIndicator(
                      count: onBoardData.length,
                      currentIndex: currentIndex,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isLastPage) {
                              _finishOnboarding();
                            } else {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 420),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            backgroundColor: const Color(0xff6f5430),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLastPage ? 'ورود به پند پارسی' : 'ادامه',
                                style: const TextStyle(
                                  fontFamily: 'Roya',
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8), // فاصله بین لیبل و آیکن
                              Icon(
                                isLastPage
                                    ? Icons.auto_awesome
                                    : Icons.arrow_forward_rounded,
                                size: 21,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.item, required this.compact});

  final OnBoardModel item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, compact ? 8 : 24, 24, 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: compact ? 180 : 250,
              child: Hero(
                tag: item.image,
                child: Image.asset(item.image, fit: BoxFit.contain),
              ),
            ),
            SizedBox(height: compact ? 14 : 24),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 18 : 24,
                vertical: compact ? 20 : 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xfffff8e9).withOpacity(.93),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xffc7a76a).withOpacity(.45),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Roya',
                      fontSize: compact ? 23 : 27,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff3c2201),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Roya',
                      fontSize: compact ? 16 : 18,
                      height: 1.65,
                      color: const Color(0xff4e4133),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentIndex == index ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                currentIndex == index
                    ? const Color(0xff6f5430)
                    : const Color(0xffd5bd91),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
