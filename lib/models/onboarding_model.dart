class OnBoardModel {
  final String title;
  final String description;
  final String image;

  OnBoardModel({
    required this.title,
    required this.description,
    required this.image,
  });
}

List<OnBoardModel> onBoardData = [
  OnBoardModel(
    title: 'به پند پارسی خوش آمدید 🌿',
    description: 'گنجینه‌ای از پندهای بزرگان، برای آرامش ذهن و رشد شخصیت شما!',
    image: 'assets/images/pandlogo.png',
  ),
  OnBoardModel(
    title: 'پندهای متنوع 📚',
    description:
        'در صفحه پندها از شاعران، اندیشمندان، رهبران و نویسندگان، پندهای ارزشمند بخوانید. با کلیک روی عنوان «پندهای پارسی» می‌توانید پندها را فیلترشده مشاهده کنید.',
    image: 'assets/images/on3.png',
  ),
  OnBoardModel(
    title: 'افزودن پند جدید ➕',
    description:
        'با کلیک روی نشانه افزودن در صفحه پندها، پند جدید به گنجینه پندهای پارسی اضافه کنید.',
    image: 'assets/images/on4.png',
  ),
  OnBoardModel(
    title: 'واکنش به پندها ✨',
    description:
        'با کلیک روی یکی از دکمه‌(اشتراک‌گذاری، قلب، سه نقطه) به پند مدنظر واکنش نشان دهید. با کلیک روی اشتراک‌گذاری میتوانید پند را کپی کنید یا به دوستان‌تان بفرستید. و با کلیک روی قلب پند را به صفحه علاقمندی انتقال دهید. با کلیک روی سه نقطه میتوانید پند را اصلاح و حذف کنید. ',
    image: 'assets/images/on5.png',
  ),
  OnBoardModel(
    title: 'علاقه‌مندی ❤',
    description:
        'در صفحه علاقمندی‌ها، پندهای پسندیده‌تان را شخصی‌سازی کنید و به اشتراک بگذارید.',
    image: 'assets/images/on6.png',
  ),
  OnBoardModel(
    title: 'پند روزانه 🔔',
    description: 'برنامه پند پارسی، هر روز یک یا دو پند اعلان می‌کند.',
    image: 'assets/images/on8.png',
  ),
];
