import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pande_parsi/databases/local_dtb.dart';
import 'package:pande_parsi/models/pand.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

enum StateOfSelectPicture { gallery, net, nothing }

class FavoritesPand extends StatefulWidget {
  const FavoritesPand({super.key});

  @override
  State<FavoritesPand> createState() => _FavoritesPandState();
}

class _FavoritesPandState extends State<FavoritesPand> {
  final List<Pand> _favorites = [];
  int currentIndex = 0;
  bool _isLoading = true;
  bool _isCapturing = false;

  String? backgroundUrl;
  File? _pickedImage;

  StateOfSelectPicture _stateOfSelectPicture = StateOfSelectPicture.nothing;

  final _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final allPands = await LocalDtb.instance.getAllPands();
    if (!mounted) return;
    setState(() {
      _favorites
        ..clear()
        ..addAll(allPands.where((p) => p.isFavorite));
      _isLoading = false;
    });
  }

  void _next() {
    if (_favorites.isNotEmpty && currentIndex < _favorites.length - 1) {
      setState(() => currentIndex++);
    }
  }

  void _prev() {
    if (_favorites.isNotEmpty && currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  /// ================= PICK IMAGE =================
  Future<void> _pickImageFromGallery() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (picked != null) {
        setState(() {
          _pickedImage = File(picked.path);
          backgroundUrl = null;
        });
      }
    } catch (e) {
      _showSnack('خطا در انتخاب تصویر');
    }
  }

  /// ================= DIALOG =================
  void _changeBackgroundDialog() {
    final controller = TextEditingController();
    bool isLoading = false;

    _stateOfSelectPicture = StateOfSelectPicture.nothing;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Widget content;

            if (_stateOfSelectPicture == StateOfSelectPicture.nothing) {
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogButton(
                    icon: Icons.image,
                    text: 'انتخاب از گالری',
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _pickImageFromGallery();
                    },
                  ),
                  const SizedBox(height: 10),
                  _dialogButton(
                    icon: Icons.link,
                    text: 'استفاده از لینک اینترنتی',
                    onTap: () {
                      setDialogState(() {
                        _stateOfSelectPicture = StateOfSelectPicture.net;
                      });
                    },
                  ),
                ],
              );
            } else {
              content = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: 'http://example.com/image.jpg',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLoading) const CircularProgressIndicator(),
                ],
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                _stateOfSelectPicture == StateOfSelectPicture.net
                    ? 'آدرس تصویر را وارد کنید'
                    : 'انتخاب پس‌زمینه',
                textDirection: TextDirection.rtl,
              ),
              content: content,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('لغو'),
                ),
                if (_stateOfSelectPicture == StateOfSelectPicture.net)
                  TextButton(
                    onPressed: () async {
                      final url = controller.text.trim();

                      if (url.isEmpty) {
                        _showSnack('لینک را وارد کنید');
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final uri = Uri.tryParse(url);
                        if (uri == null) throw Exception();

                        final response = await HttpClient().getUrl(uri);
                        await response.close();

                        setState(() {
                          backgroundUrl = url;
                          _pickedImage = null;
                        });

                        Navigator.pop(ctx);
                      } catch (_) {
                        setDialogState(() => isLoading = false);
                        _showSnack(
                          'لینک تصویر معتبر نیست یا اینترنت مشکل دارد',
                        );
                      }
                    },
                    child: const Text('تأیید'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 58,
            color: const Color(0xff9c7e44).withOpacity(.8),
          ),
          const SizedBox(height: 12),
          const Text(
            'هنوز پندی به علاقه‌مندی‌ها اضافه نکرده‌اید',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Roya',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff422d0f),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'پندهای دوست‌داشتنی خود را با لمس قلب ذخیره کنید.',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Roya',
              fontSize: 16,
              color: Color(0xff5b4a37),
            ),
          ),
        ],
      ),
    );
  }

  Widget _favoriteHeader() {
    return Positioned(
      top: 14,
      left: 20,
      right: 20,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              'علاقه‌مندی‌های من',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Roya',
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xff3c2201),
                shadows: [
                  Shadow(color: Colors.white70, blurRadius: 5),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xfffde8bd).withOpacity(.95),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: Colors.redAccent, size: 19),
                const SizedBox(width: 6),
                Text(
                  '${_favorites.length} پند',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontFamily: 'Roya',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff422d0f),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= SHARE =================
  Future<void> _shareScreenshot() async {
    setState(() => _isCapturing = true);

    // افکت Fade
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final image = await _screenshotController.capture();

      setState(() => _isCapturing = false);

      if (image != null) {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/shot_${DateTime.now().millisecondsSinceEpoch}.png',
        );

        await file.writeAsBytes(image);

        await Share.shareXFiles([XFile(file.path)], text: 'پند موردعلاقه من');
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      _showSnack('خطا در گرفتن اسکرین‌شات');
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  bool _isTextWithinCadrBounds(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 21, fontFamily: 'Roya'),
      ),
      textDirection: TextDirection.rtl,
    );

    textPainter.layout(maxWidth: 300);

    return textPainter.width <= 300 && textPainter.height <= 145;
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Screenshot(
          controller: _screenshotController,
          child: Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  backgroundUrl == null
                      ? (_pickedImage == null
                          ? Image.asset(
                            'assets/images/background.jpg',
                            height: double.infinity,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                          : FadeInImage(
                            placeholder: AssetImage(
                              'assets/images/background.jpg',
                            ),
                            image: FileImage(_pickedImage!),
                            height: double.infinity,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ))
                      : FadeInImage(
                        placeholder: AssetImage('assets/images/background.jpg'),
                        image: NetworkImage(backgroundUrl!),
                        height: double.infinity,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        imageErrorBuilder:
                            (_, __, ___) => Image.asset(
                              'assets/images/background.jpg',
                              fit: BoxFit.cover,
                            ),
                      ),

                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff6f5430),
                      ),
                    ),
                  if (!_isLoading)
                    Center(
                    child: Container(
                      margin: EdgeInsets.all(18),
                      child: Stack(
                        children: [
                          Center(
                            child:
                                backgroundUrl == null && _pickedImage == null
                                    ? Stack(
                                      children: [
                                        if (_favorites.isNotEmpty &&
                                            _isTextWithinCadrBounds(
                                              _favorites[currentIndex].sentence,
                                            ))
                                          Center(
                                            child: Image.asset(
                                              'assets/images/cadr.png',
                                            ),
                                          ),
                                        Center(
                                          child: SingleChildScrollView(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 15,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(40),
                                              child:
                                                  _favorites.isEmpty
                                                      ? _emptyState()
                                                      : Column(
                                                        children: [
                                                          Text(
                                                            _favorites[currentIndex]
                                                                .sentence,
                                                            style: TextStyle(
                                                              fontSize: 21,
                                                              fontFamily:
                                                                  'Roya',
                                                            ),
                                                            textAlign:
                                                                TextAlign.right,
                                                            textDirection:
                                                                TextDirection
                                                                    .rtl,
                                                          ),
                                                          Align(
                                                            alignment:
                                                                Alignment
                                                                    .centerRight,
                                                            child: Text(
                                                              _favorites[currentIndex]
                                                                  .teller,
                                                              style: TextStyle(
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                    : Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                        horizontal: 55,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(200),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child:
                                          _favorites.isEmpty
                                              ? _emptyState()
                                              : Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _favorites[currentIndex]
                                                        .sentence,
                                                    style: TextStyle(
                                                      fontSize: 21,
                                                      fontFamily: 'Roya',
                                                    ),
                                                    textAlign: TextAlign.right,
                                                    textDirection:
                                                        TextDirection.rtl,
                                                  ),
                                                  SizedBox(height: 10),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      _favorites[currentIndex]
                                                          .teller,
                                                      style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                    ),
                          ),
                          if (_favorites.isNotEmpty)
                            Center(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Color(0xffe6d1a6),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.keyboard_arrow_left_rounded,
                                      ),
                                      onPressed: _prev,
                                    ),
                                  ),
                                  CircleAvatar(
                                    backgroundColor: Color(0xffe6d1a6),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.keyboard_arrow_right_rounded,
                                      ),
                                      onPressed: _next,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!_isCapturing && !_isLoading) _favoriteHeader(),
                  if (!_isCapturing && !_isLoading)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 390;
                          final buttons = [
                          ElevatedButton.icon(
                            onPressed: _changeBackgroundDialog,
                            icon: Icon(
                              Icons.image_outlined,
                              color: Colors.white,
                            ),
                            label: Text(
                              'تغییر پس‌زمینه',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff9c7e44),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                _favorites.isNotEmpty ? _shareScreenshot : null,
                            icon: Icon(Icons.camera, color: Colors.white),
                            label: Text(
                              'اسکرین‌شات',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _favorites.isNotEmpty
                                      ? Color(0xff9c7e44)
                                      : Colors.grey,
                            ),
                          ),
                          ];

                          return compact
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  buttons[0],
                                  const SizedBox(height: 8),
                                  buttons[1],
                                ],
                              )
                              : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: buttons,
                              );
                        },
                      ),
                    ),

                  if (_isCapturing)
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 200),
                        opacity: _isCapturing ? 1 : 0,
                        child: Container(color: Colors.white.withOpacity(0.2)),
                      ),
                    ),

                  if (_isCapturing)
                    Positioned(
                      bottom: 70,
                      left: (MediaQuery.of(context).size.width - 60) / 2,
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Opacity(
                          opacity: 0.6,
                          child: Image.asset(
                            'assets/images/pandlogo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
