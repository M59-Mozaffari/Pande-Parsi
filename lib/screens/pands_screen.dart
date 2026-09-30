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
  bool _hasScrolledToNotification = false;

  final ItemScrollController _itemScrollController = ItemScrollController();

  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  double _scrollProgress = 0.0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initData();

    /// گوش دادن به Sync مرکزی
    _syncSub = SyncManager.instance.onSync.listen((_) {
      _loadLocalPands();
    });

    /// محاسبه موقعیت اسکرول
    _itemPositionsListener.itemPositions.addListener(() {
      final filteredPands = _filteredPands;

      if (filteredPands.isEmpty) return;

      final positions = _itemPositionsListener.itemPositions.value;

      if (positions.isEmpty) return;

      final visiblePositions =
          positions.where((p) => p.itemTrailingEdge > 0).toList();

      if (visiblePositions.isEmpty) return;

      final minIndex = visiblePositions
          .map((p) => p.index)
          .reduce((a, b) => a < b ? a : b);

      final progress =
          filteredPands.length <= 1
              ? 0.0
              : minIndex / (filteredPands.length - 1);

      if (!mounted) return;

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

  // ============================================================
  // FILTERED DATA
  // ============================================================

  List<Pand> get _filteredPands {
    if (_selectedCategory == null) {
      return _pands;
    }

    return _pands.where((pand) => pand.category == _selectedCategory).toList();
  }

  int _categoryCount(Category category) {
    return _pands.where((pand) => pand.category == category).length;
  }

  // ============================================================
  // INIT DATA
  // ============================================================

  Future<void> _initData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      await _loadLocalPands();

      if (_pands.isEmpty && mounted) {
        setState(() {
          _errorMessage =
              'برای دریافت پندها از شبکه، لطفا اینترنت را روشن کنید.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطا در دریافت اطلاعات';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadLocalPands() async {
    final pands = await localDtb.getAllPands();

    if (!mounted) return;

    setState(() {
      _pands = pands;
    });

    if (_pands.isEmpty) return;

    /// اسکرول رندوم اولیه
    if (!_initialScrollDone && widget.initialPandId == null) {
      _initialScrollDone = true;

      _scrollToRandomPosition();
    }

    /// اسکرول نوتیفیکیشن
    if (!_hasScrolledToNotification &&
        widget.initialPandId != null &&
        widget.scrollToPand) {
      _hasScrolledToNotification = true;

      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;

        _scrollToPand(widget.initialPandId!, type: ScrollType.notification);
      });
    }
  }

  // ============================================================
  // SCROLL
  // ============================================================

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

    if (!_itemScrollController.isAttached) {
      return;
    }

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

    if (!mounted) return;

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

  void _scrollToRandomPosition() {
    if (_pands.isEmpty) return;

    if (_pands.length == 1) {
      return;
    }

    final random = Random();

    int index;

    final section = random.nextInt(3);

    if (section == 0) {
      final end = max(1, (_pands.length * 0.25).toInt());

      index = random.nextInt(end);
    } else if (section == 1) {
      final start = (_pands.length * 0.35).toInt();

      final end = max(start + 1, (_pands.length * 0.65).toInt());

      index = start + random.nextInt(end - start);
    } else {
      final start = min(_pands.length - 1, (_pands.length * 0.75).toInt());

      index = start + random.nextInt(max(1, _pands.length - start));
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (_itemScrollController.isAttached) {
        _itemScrollController.jumpTo(index: index.clamp(0, _pands.length - 1));
      }
    });
  }

  // ============================================================
  // ADD PAND
  // ============================================================

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
        if (mounted) {
          _scrollToPand(pandId, type: ScrollType.newPand);
        }
      });
    }
  }

  // ============================================================
  // CATEGORY TITLE
  // ============================================================

  String _getButtonText() {
    if (_selectedCategory == null) {
      return 'پندهای پارسی';
    }

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

  // ============================================================
  // CATEGORY MENU ITEM
  // ============================================================

  Widget _menuItem({
    required IconData icon,
    required String text,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? const Color(0xfff5dfaa) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: const Color(0xff8a7249).withOpacity(0.10),
          highlightColor: const Color(0xff8a7249).withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                /// آیکون
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? const Color(0xffefd394)
                            : const Color(0xfff7e7bd),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color(0xffb89556).withOpacity(0.35),
                    ),
                  ),
                  child: Icon(icon, color: const Color(0xff60492b), size: 23),
                ),

                const SizedBox(width: 12),

                /// عنوان
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Roya',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff3c2201),
                    ),
                  ),
                ),

                /// تعداد
                Container(
                  constraints: const BoxConstraints(minWidth: 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffead39b),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Roya',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff60492b),
                    ),
                  ),
                ),

                const SizedBox(width: 7),

                /// وضعیت انتخاب
                SizedBox(
                  width: 24,
                  child:
                      selected
                          ? const Icon(
                            Icons.check_rounded,
                            size: 21,
                            color: Color(0xff60492b),
                          )
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY MENU
  // ============================================================

  void _showCategoryMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xfffde8bd),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 9, 8, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// دستگیره
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xff8a7249).withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// عنوان منو
                    Row(
                      children: [
                        const SizedBox(width: 15),

                        const Expanded(
                          child: Text(
                            'دسته‌بندی پندها',
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'Roya',
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff3c2201),
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                          splashRadius: 22,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xff60492b),
                          ),
                        ),
                      ],
                    ),

                    /// توضیح کوتاه
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'پندها را بر اساس نوع گوینده مشاهده کنید.',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Roya',
                            fontSize: 15,
                            color: Color(0xff806a45),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// همه
                    _menuItem(
                      icon: Icons.grid_view_rounded,
                      text: 'همه پندها',
                      count: _pands.length,
                      selected: _selectedCategory == null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = null;
                          _scrollProgress = 0.0;
                        });

                        Navigator.pop(ctx);

                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (_itemScrollController.isAttached &&
                              _filteredPands.isNotEmpty) {
                            _itemScrollController.jumpTo(index: 0);
                          }
                        });
                      },
                    ),

                    /// شاعران
                    _menuItem(
                      icon: Icons.auto_stories_rounded,
                      text: 'پند شاعران',
                      count: _categoryCount(Category.poet),
                      selected: _selectedCategory == Category.poet,
                      onTap: () {
                        setState(() {
                          _selectedCategory = Category.poet;
                          _scrollProgress = 0.0;
                        });

                        Navigator.pop(ctx);

                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (_itemScrollController.isAttached &&
                              _filteredPands.isNotEmpty) {
                            _itemScrollController.jumpTo(index: 0);
                          }
                        });
                      },
                    ),

                    /// رهبران
                    _menuItem(
                      icon: Icons.account_balance_rounded,
                      text: 'پند رهبران',
                      count: _categoryCount(Category.leader),
                      selected: _selectedCategory == Category.leader,
                      onTap: () {
                        setState(() {
                          _selectedCategory = Category.leader;
                          _scrollProgress = 0.0;
                        });

                        Navigator.pop(ctx);

                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (_itemScrollController.isAttached &&
                              _filteredPands.isNotEmpty) {
                            _itemScrollController.jumpTo(index: 0);
                          }
                        });
                      },
                    ),

                    /// نویسندگان
                    _menuItem(
                      icon: Icons.menu_book_rounded,
                      text: 'پند نویسندگان',
                      count: _categoryCount(Category.writer),
                      selected: _selectedCategory == Category.writer,
                      onTap: () {
                        setState(() {
                          _selectedCategory = Category.writer;
                          _scrollProgress = 0.0;
                        });

                        Navigator.pop(ctx);

                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (_itemScrollController.isAttached &&
                              _filteredPands.isNotEmpty) {
                            _itemScrollController.jumpTo(index: 0);
                          }
                        });
                      },
                    ),

                    /// اندیشمندان
                    _menuItem(
                      icon: Icons.psychology_alt_rounded,
                      text: 'پند اندیشمندان',
                      count: _categoryCount(Category.thinker),
                      selected: _selectedCategory == Category.thinker,
                      onTap: () {
                        setState(() {
                          _selectedCategory = Category.thinker;
                          _scrollProgress = 0.0;
                        });

                        Navigator.pop(ctx);

                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (_itemScrollController.isAttached &&
                              _filteredPands.isNotEmpty) {
                            _itemScrollController.jumpTo(index: 0);
                          }
                        });
                      },
                    ),

                    /// هنرمندان
                    _menuItem(
                      icon: Icons.palette_outlined,
                      text: 'پند هنرمندان',
                      count: _categoryCount(Category.artist),
                      selected: _selectedCategory == Category.artist,
                      onTap: () {
                        setState(() {
                          _selectedCategory = Category.artist;
                          _scrollProgress = 0.0;
                        });

                        Navigator.pop(ctx);

                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (_itemScrollController.isAttached &&
                              _filteredPands.isNotEmpty) {
                            _itemScrollController.jumpTo(index: 0);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredPands = _filteredPands;

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
            /// پس‌زمینه اصلی
            Image.asset(
              'assets/images/pndha.jpg',
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Container(color: Colors.black.withOpacity(0.1)),

            /// محتوای صفحه
            Column(
              children: [
                const SizedBox(height: 4),

                // =================================================
                // عنوان قابل لمس و منوی دسته‌بندی
                // =================================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _showCategoryMenu,
                      splashColor: const Color(0xff8a7249).withOpacity(0.10),
                      highlightColor: const Color(0xff8a7249).withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getButtonText(),
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    fontFamily: 'Roya',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 34,
                                    color: Color(0xff3c2201),
                                  ),
                                ),

                                const SizedBox(width: 3),

                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 28,
                                  color: const Color(
                                    0xff60492b,
                                  ).withOpacity(0.85),
                                ),
                              ],
                            ),

                            const SizedBox(height: 2),

                            /// خط ظریف زیر عنوان
                            Container(
                              width: 210,
                              height: 1,
                              color: const Color(0xff8a7249).withOpacity(0.35),
                            ),

                            const SizedBox(height: 3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // =================================================
                // لیست پندها
                // =================================================
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

            // =====================================================
            // FAST SCROLL
            // =====================================================
            // =====================================================
            // =====================================================
            // FAST SCROLL
            // =====================================================
            Positioned(
              right: 7,
              top: 120,
              bottom: 120,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackHeight = constraints.maxHeight;

                  const double thumbHeight = 54;

                  final movableHeight = max(0.0, trackHeight - thumbHeight);

                  // حرکت به موقعیت انتخاب‌شده روی خط
                  void scrollToPosition(double dy) {
                    final filteredPands = _filteredPands;

                    if (filteredPands.isEmpty) return;

                    final clampedDy = dy.clamp(0.0, trackHeight);

                    final thumbTop = (clampedDy - thumbHeight / 2).clamp(
                      0.0,
                      movableHeight,
                    );

                    final progress =
                        movableHeight <= 0 ? 0.0 : thumbTop / movableHeight;

                    final index =
                        (progress * (filteredPands.length - 1)).round();

                    if (_itemScrollController.isAttached) {
                      _itemScrollController.jumpTo(
                        index: index.clamp(0, filteredPands.length - 1),
                      );
                    }
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,

                    // لمس هر نقطه از خط
                    onTapUp: (details) {
                      scrollToPosition(details.localPosition.dy);
                    },

                    // کشیدن نشانگر
                    onVerticalDragUpdate: (details) {
                      scrollToPosition(details.localPosition.dy);
                    },

                    child: SizedBox(
                      width: 24,
                      height: trackHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ---------------------------------------
                          // خط اصلی اسکرول
                          // ---------------------------------------

                          Positioned(
                            left: 10,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2.5,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.32),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          // ---------------------------------------
                          // نشانگر ظریف و هنرمندانه
                          // ---------------------------------------
                          Positioned(
                            top: _scrollProgress * movableHeight,
                            left: 3,
                            child: Container(
                              width: 18,
                              height: thumbHeight,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xff5a4022,
                                ).withOpacity(0.78),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xffe8d19c,
                                  ).withOpacity(0.75),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.10),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),

                              // -----------------------------------
                              // دو خط تزئینی وسط نشانگر
                              // -----------------------------------
                              child: Center(
                                child: SizedBox(
                                  width: 8,
                                  height: 24,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 1.2,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xfff0d8a3,
                                          ).withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 8,
                                        height: 1.2,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xfff0d8a3,
                                          ).withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(List<Pand> filteredPands) {
    if (_isLoading && _pands.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _pands.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roya',
              fontSize: 17,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    if (filteredPands.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 42,
              color: Color(0xff8a7249),
            ),

            const SizedBox(height: 10),

            const Text(
              'در این دسته پندی یافت نشد',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roya',
                fontSize: 18,
                color: Color(0xff60492b),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              _getButtonText(),
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Roya',
                fontSize: 14,
                color: Color(0xff806a45),
              ),
            ),
          ],
        ),
      );
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      itemCount: filteredPands.length,
      padding: const EdgeInsets.only(top: 2, bottom: 15),
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
