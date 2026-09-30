import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pande_parsi/databases/sync_manager.dart';
import 'package:pande_parsi/screens/pands_screen.dart';
import 'package:pande_parsi/screens/favorites_pand.dart';
import './search_screen.dart';
import '../widgets/about.dart';
import 'dart:math';
import 'package:pande_parsi/databases/local_dtb.dart';
import 'package:pande_parsi/models/pand.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final localDtb = LocalDtb.instance;

  List<Pand> _pands = [];
  bool isLoading = true;
  Pand? _randomPand;

  StreamSubscription? _syncSub;

  @override
  void initState() {
    super.initState();
    _initHomeData();

    _syncSub = SyncManager.instance.onSync.listen((_) {
      _loadLocalPands();
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  Future<void> _initHomeData() async {
    await _loadLocalPands();

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _loadLocalPands() async {
    final pands = await localDtb.getAllPands();

    if (!mounted) return;
    setState(() {
      _pands = pands;
    });
  }

  Pand _getRandomPand() {
    final random = Random();
    return _pands[random.nextInt(_pands.length)];
  }

  void _showRandomPandDialog() {
    if (_pands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: const Text(
            'هنوز پندی وجود ندارد! لطفا اینترنت را روشن کنید تا پندها بارگیری شود.',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      return;
    }

    _randomPand = _getRandomPand();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Pand",
      barrierColor: Colors.black.withOpacity(0.5),

      transitionDuration: Duration(milliseconds: 400),

      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 30),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xfffde8bd),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// متن پند
                      Text(
                        _randomPand!.sentence,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Roya',
                          fontSize: 22,
                          color: Color(0xff3c2201),
                          height: 1.6,
                          wordSpacing: -2,
                        ),
                      ),

                      SizedBox(height: 10),

                      /// نویسنده
                      Text(
                        '- ${_randomPand!.teller}',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Roya',
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),

                      SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// 🎲 شافل
                          IconButton(
                            onPressed: () {
                              setStateDialog(() {
                                _randomPand = _getRandomPand();
                              });
                            },
                            icon: Icon(Icons.shuffle, color: Color(0xff3c2201)),
                          ),

                          /// بستن
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },

      /// ✨ انیمیشن ورود
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(opacity: anim1.value, child: child),
        );
      },
    );
  }

  Widget _card(Function() onTap, String cardTitle, IconData icon) {
    return _HomeActionCard(
      onTap: onTap,
      title: cardTitle,
      icon: Icon(icon, size: 34, color: const Color(0xff422d0f)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 20, right: 40, left: 40),
                    child: Image.asset('assets/images/pandlogo.png'),
                  ),
                  SizedBox(height: 13),
                  _HomeActionCard(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => PandsScreen()),
                      );
                    },
                    title: 'پندها',
                    icon: const FaIcon(
                      FontAwesomeIcons.book,
                      size: 30,
                      color: Color(0xff422d0f),
                    ),
                  ),

                  const SizedBox(height: 10),
                  _card(_showRandomPandDialog, 'پند بگیر', Icons.auto_awesome),
                  const SizedBox(height: 10),
                  _card(
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => SearchScreen()),
                      );
                    },
                    'جستجو',
                    Icons.search,
                  ),
                  const SizedBox(height: 10),
                  _card(
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FavoritesPand(),
                        ),
                      );
                    },
                    'علاقمندی‌ها',
                    Icons.bookmark_border,
                  ),
                  const SizedBox(height: 10),

                  _card(
                    () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AboutDialogPro(),
                      );
                    },
                    'درباره',
                    Icons.info_outline,
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

class _HomeActionCard extends StatefulWidget {
  const _HomeActionCard({
    required this.onTap,
    required this.title,
    required this.icon,
  });

  final VoidCallback onTap;
  final String title;
  final Widget icon;

  @override
  State<_HomeActionCard> createState() => _HomeActionCardState();
}

class _HomeActionCardState extends State<_HomeActionCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (mounted && _isPressed != value) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalMargin = constraints.maxWidth < 360 ? 16.0 : 28.0;
        final titleSize = constraints.maxWidth < 360 ? 28.0 : 32.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Material(
              color: const Color(0xfffde8bd),
              elevation: _isPressed ? 3 : 6,
              shadowColor: Colors.black.withOpacity(.2),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => _setPressed(true),
                onTapUp: (_) => _setPressed(false),
                onTapCancel: () => _setPressed(false),
                borderRadius: BorderRadius.circular(20),
                splashColor: const Color(0xffc99d5b).withOpacity(.22),
                highlightColor: Colors.transparent,
                child: SizedBox(
                  height: 76,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        widget.icon,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Roya',
                              color: const Color(0xff422d0f),
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
