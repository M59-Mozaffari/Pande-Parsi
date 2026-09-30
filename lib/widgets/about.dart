import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutDialogPro extends StatelessWidget {
  const AboutDialogPro({super.key});

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.brown,
        duration: Duration(seconds: 1),
        content: Text(
          "ایمیل کپی شد.",
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _tile({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, color: Colors.brown, size: 22),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    title,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Roya',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Roya',
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            if (onTap != null)
              const Icon(Icons.copy, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.95, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: scale, child: child),
        );
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xfffde8bd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// 🔥 هدر گرادینتی
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 90,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xfff6c667), Color(0xfff29f05)],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                  ),

                  /// لوگو شناور
                  Positioned(
                    bottom: -35,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(blurRadius: 12, color: Colors.black26),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/pandlogo.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 45),

              /// عنوان
              const Text(
                "پند پارسی",
                style: TextStyle(
                  fontFamily: 'Roya',
                  fontSize: 18,
                  wordSpacing: -3,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 2),

              const Text(
                "نسخه 1.0",
                style: TextStyle(
                  fontFamily: 'Roya',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 10),

              /// اطلاعات
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    _tile(
                      context: context,
                      title: "توسعه‌دهنده",
                      value: "مهدی مظفری",
                      icon: Icons.person_outline,
                    ),
                    _tile(
                      context: context,
                      title: "ایمیل",
                      value: "mozaffari.m11059@gmail.com",
                      icon: Icons.email_outlined,
                      onTap: () => _copy(context, "mozaffari.m11059@gmail.com"),
                    ),
                    _tile(
                      context: context,
                      title: "شماره تماس (متصل به واتس‌اپ و تلگرام)",
                      value: "0749951615 (93+) ",
                      icon: Icons.phone_android,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// دکمه
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "بستن",
                      style: TextStyle(
                        fontFamily: 'Roya',
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
