import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pande_parsi/databases/sync_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:pande_parsi/databases/local_dtb.dart';
import 'package:pande_parsi/models/pand.dart';
import 'package:pande_parsi/widgets/add_pand.dart';
import 'package:pande_parsi/widgets/style_pand.dart';

enum ScrollType { newPand, editedPand, notification }

class PandsScreen extends StatefulWidget {
  final int? initialPandId;
  final bool scrollToPand;

  const PandsScreen({super.key, this.initialPandId, this.scrollToPand = false});

  @override
  State<PandsScreen> createState() => _PandsScreenState();
}

class _PandsScreenState extends State<PandsScreen> {
  final localDtb = LocalDtb.instance;

  StreamSubscription? _syncSub;

  ScrollType? scrollType;
  int? shakePandId;

  List<Pand> _pands = [];

  Category? _selectedCategory;

  bool _isLoading = true;
  String? _errorMessage;

  int? _highlightPandId;

  bool _initialScrollDone = false;
  bool _hasScrolledToNotification = false; // 👈 مهم

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _initData();

    /// ✅ گوش دادن به sync مرکزی
    _syncSub = SyncManager.instance.onSync.listen((_) {
      _loadLocalPands();
    });

    /// اسکرول‌بار
    _itemPositionsListener.itemPositions.addListener(() {
      if (_pands.isEmpty) return;

      final positions = _itemPositionsListener.itemPositions.value;

      if (positions.isEmpty) return;

      final min = positions
          .where((p) => p.itemTrailingEdge > 0)
          .map((p) => p.index)
          .reduce((a, b) => a < b ? a : b);

      final progress = min / _pands.length;

      setState(() {
        _scrollProgress = progress.clamp(0.0, 1.0);
      });
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  // ================= INIT =================

  Future<void> _initData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _loadLocalPands();

      if (_pands.isEmpty) {
        setState(() {
          _errorMessage =
              'برای دریافت پندها از شبکه، لطفا اینترنت را روشن کنید.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطا در دریافت اطلاعات';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ================= LOAD =================

  Future<void> _loadLocalPands() async {
    final pands = await localDtb.getAllPands();

    setState(() {
      _pands = pands;
    });

    if (_pands.isEmpty) return;

    /// 🎲 اسکرول رندوم اولیه
    if (!_initialScrollDone && widget.initialPandId == null) {
      _initialScrollDone = true;
      _scrollToRandomPosition();
    }

    /// 🔥 اسکرول نوتیف (کاملاً ایمن)
    if (!_hasScrolledToNotification &&
        widget.initialPandId != null &&
        widget.scrollToPand) {
      _hasScrolledToNotification = true;

      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollToPand(widget.initialPandId!, type: ScrollType.notification);
      });
    }
  }

  // ================= SCROLL =================

  void _scrollToPand(
    int pandId, {
    ScrollType type = ScrollType.newPand,
    int attempt = 0,
  }) async {
    if (attempt >= 10) return;

    final index = _pands.indexWhere((pand) => pand.id == pandId);

    if (index == -1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _scrollToPand(pandId, type: type, attempt: attempt + 1);
        }
      });
      return;
    }

    await Future.delayed(const Duration(milliseconds: 250));

    if (_itemScrollController.isAttached) {
      double alignment = 0.5;

      if (type == ScrollType.notification) {
        alignment = 0.2;
      }

      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        alignment: alignment,
      );

      setState(() {
        _highlightPandId = pandId;
        scrollType = type;
      });

      if (type == ScrollType.editedPand) {
        setState(() {
          shakePandId = pandId;
        });

        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              shakePandId = null;
            });
          }
        });
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightPandId = null;
            scrollType = null;
          });
        }
      });
    }
  }

  void _scrollToRandomPosition() {
    if (_pands.isEmpty) return;

    final random = Random();

    int index;

    final section = random.nextInt(3);

    if (section == 0) {
      index = random.nextInt((_pands.length * 0.25).toInt());
    } else if (section == 1) {
      final start = (_pands.length * 0.35).toInt();
      final end = (_pands.length * 0.65).toInt();
      index = start + random.nextInt(end - start);
    } else {
      final start = (_pands.length * 0.75).toInt();
      index = start + random.nextInt(_pands.length - start);
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (_itemScrollController.isAttached) {
        _itemScrollController.jumpTo(index: index);
      }
    });
  }

  void _fastScroll(double dy, double height) {
    final percent = (dy / height).clamp(0.0, 1.0);

    final index = (percent * _pands.length).toInt();

    if (_itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: index.clamp(0, _pands.length - 1));
    }
  }

  // ================= ADD =================

  void _addToPand() async {
    final pandId = await showModalBottomSheet<int>(
      backgroundColor: const Color(0xfffde8bd),
      isScrollControlled: true,
      context: context,
      builder: (ctx) => const AddPand(),
    );

    if (pandId != null) {
      await _loadLocalPands();

      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToPand(pandId, type: ScrollType.newPand);
      });
    }
  }

  // ================= CATEGORY =================

  String _getButtonText() {
    if (_selectedCategory == null) return 'پندهای پارسی';

    switch (_selectedCategory) {
      case Category.poet:
        return 'پند شاعران';
      case Category.leader:
        return 'پند رهبران';
      case Category.writer:
        return 'پند نویسندگان';
      case Category.thinker:
        return 'پند اندیشمندان';
      case Category.artist:
        return 'پند هنرمندان';
      default:
        return 'پندهای پارسی';
    }
  }

  Widget _menuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff3c2201)),
      title: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Roya',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff3c2201),
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  void _showCategoryMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xfffde8bd),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _menuItem(
                  icon: Icons.menu_book,
                  text: 'همه پندها',
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    Navigator.pop(context);
                  },
                ),
                _menuItem(
                  icon: Icons.auto_stories,
                  text: 'پند شاعران',
                  onTap: () {
                    setState(() => _selectedCategory = Category.poet);
                    Navigator.pop(context);
                  },
                ),
                _menuItem(
                  icon: Icons.account_balance,
                  text: 'پند رهبران',
                  onTap: () {
                    setState(() => _selectedCategory = Category.leader);
                    Navigator.pop(context);
                  },
                ),
                _menuItem(
                  icon: Icons.edit,
                  text: 'پند نویسندگان',
                  onTap: () {
                    setState(() => _selectedCategory = Category.writer);
                    Navigator.pop(context);
                  },
                ),
                _menuItem(
                  icon: Icons.psychology,
                  text: 'پند اندیشمندان',
                  onTap: () {
                    setState(() => _selectedCategory = Category.thinker);
                    Navigator.pop(context);
                  },
                ),
                _menuItem(
                  icon: Icons.palette,
                  text: 'پند هنرمندان',
                  onTap: () {
                    setState(() => _selectedCategory = Category.artist);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final filteredPands =
        _selectedCategory == null
            ? _pands
            : _pands.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_sharp, color: Colors.black),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/pndappbar.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(color: Colors.white.withAlpha(35)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 20),
        child: FloatingActionButton(
          heroTag: 'افزودن پند',
          onPressed: _addToPand,
          backgroundColor: const Color(0xfff0d8a3),
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Image.asset(
              'assets/images/pndha.jpg',
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.1)),
            Column(
              children: [
                TextButton(
                  onPressed: _showCategoryMenu,
                  child: Text(
                    _getButtonText(),
                    style: const TextStyle(
                      fontFamily: 'Roya',
                      fontWeight: FontWeight.bold,
                      fontSize: 34,
                      color: Color(0xff3c2201),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 34,
                    ).copyWith(bottom: 70),
                    child: _buildContent(filteredPands),
                  ),
                ),
              ],
            ),

            /// FAST SCROLL
            Positioned(
              right: 8,
              top: 120,
              bottom: 120,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onVerticalDragUpdate: (details) {
                      _fastScroll(
                        details.localPosition.dy,
                        constraints.maxHeight,
                      );
                    },
                    child: Container(
                      width: 22,
                      alignment: Alignment.topCenter,
                      child: Stack(
                        children: [
                          Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Positioned(
                            top: _scrollProgress * (constraints.maxHeight - 60),
                            child: Container(
                              width: 22,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xff3c2201),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.drag_handle,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Pand> filteredPands) {
    if (_isLoading && _pands.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _pands.isEmpty) {
      return Center(
        child: Text(
          _errorMessage!,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (filteredPands.isEmpty) {
      return const Center(
        child: Text('هیچ پندی یافت نشد', textDirection: TextDirection.rtl),
      );
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      itemCount: filteredPands.length,
      itemBuilder: (ctx, i) {
        final pand = filteredPands[i];

        final isHighlighted = pand.id == _highlightPandId;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color:
                isHighlighted
                    ? const Color(0xfff7e7a5).withOpacity(0.6)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: StylePand(pnd: pand),
        );
      },
    );
  }
}
