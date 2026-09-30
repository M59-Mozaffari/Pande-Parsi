import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pande_parsi/models/pand.dart';
import 'package:pande_parsi/databases/supabase_dtb.dart';
import 'package:pande_parsi/notifications_service.dart';

class AddPand extends StatefulWidget {
  const AddPand({super.key, this.initialPand});

  final Pand? initialPand;

  @override
  State<AddPand> createState() => _AddPandState();
}

class _AddPandState extends State<AddPand> {
  final _enteredPand = TextEditingController();
  final _enteredTitle = TextEditingController();
  final _enteredTeller = TextEditingController();

  Category _selectedCtg = Category.book;

  final pndDbs = SupabaseDtb();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialPand != null) {
      _enteredPand.text = widget.initialPand!.sentence;
      _enteredTitle.text = widget.initialPand!.title;
      _enteredTeller.text = widget.initialPand!.teller;
      _selectedCtg = widget.initialPand!.category;
    }
  }

  @override
  void dispose() {
    _enteredPand.dispose();
    _enteredTitle.dispose();
    _enteredTeller.dispose();
    super.dispose();
  }

  // =====================================================
  // FIELD DECORATION
  // =====================================================

  InputDecoration fieldDecoration(
    String label,
    IconData icon, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xff6f5837)),
      labelStyle: const TextStyle(
        fontFamily: 'Roya',
        fontSize: 16,
        color: Color(0xff6b5536),
      ),
      hintStyle: TextStyle(
        fontFamily: 'Roya',
        fontSize: 15,
        color: Colors.brown.withOpacity(.45),
      ),
      floatingLabelStyle: const TextStyle(
        fontFamily: 'Roya',
        fontSize: 16,
        color: Color(0xff5c4529),
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(.88),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xff8a7249).withOpacity(.35),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff80643d), width: 1.6),
      ),
    );
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void _showMessage(String text, {bool isError = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.redAccent : const Color(0xff606c55),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                text,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'Roya', fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =====================================================
  // CATEGORY ICON
  // =====================================================

  IconData _categoryIcon(Category category) {
    switch (category) {
      case Category.book:
        return Icons.menu_book_rounded;

      default:
        return Icons.auto_stories_rounded;
    }
  }

  // =====================================================
  // CATEGORY SELECTOR
  // =====================================================

  Widget _categorySelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _isLoading ? null : _showCategoryMenu,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xff8a7249).withOpacity(.35)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // آیکون دسته‌بندی
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xffe8dbb8).withOpacity(.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcon(_selectedCtg),
                color: const Color(0xff6b4e2e),
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            // عنوان و دسته انتخاب‌شده
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'دسته‌بندی',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'Roya',
                      fontSize: 13,
                      color: Color(0xff8a7249),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    persionCtg[_selectedCtg]!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Roya',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff3c2201),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xff6b4e2e),
              size: 25,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // CATEGORY MENU
  // =====================================================

  Future<void> _showCategoryMenu() async {
    final selected = await showModalBottomSheet<Category>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xfff8efd9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // دستگیره
                  Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xff8a7249).withOpacity(.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // عنوان
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xffe8dbb8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.category_rounded,
                          color: Color(0xff6b4e2e),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'انتخاب دسته‌بندی',
                          style: TextStyle(
                            fontFamily: 'Roya',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff3c2201),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xff6b4e2e),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // دسته‌بندی‌ها
                  ...Category.values.map((category) {
                    final isSelected = category == _selectedCtg;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(context, category);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xffe8dbb8)
                                    : Colors.white.withOpacity(.72),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? const Color(0xff8a7249)
                                      : const Color(
                                        0xff8a7249,
                                      ).withOpacity(.22),
                              width: isSelected ? 1.4 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(0xffd8c79e)
                                          : const Color(0xffeee5cf),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _categoryIcon(category),
                                  color: const Color(0xff6b4e2e),
                                  size: 21,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  persionCtg[category]!,
                                  style: TextStyle(
                                    fontFamily: 'Roya',
                                    fontSize: 17,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color: const Color(0xff3c2201),
                                  ),
                                ),
                              ),

                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child:
                                    isSelected
                                        ? const Icon(
                                          Icons.check_circle_rounded,
                                          key: ValueKey('selected'),
                                          color: Color(0xff6f5837),
                                          size: 24,
                                        )
                                        : const Icon(
                                          Icons.radio_button_unchecked,
                                          key: ValueKey('unselected'),
                                          color: Color(0xffb6a383),
                                          size: 22,
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedCtg = selected;
      });
    }
  }

  // =====================================================
  // SUBMIT
  // =====================================================

  Future<void> _submitData() async {
    if (_isLoading) return;

    if (_enteredPand.text.trim().isEmpty) {
      _showMessage('لطفاً متن پند را وارد کنید!');
      return;
    }

    if (_enteredTitle.text.trim().isEmpty) {
      _showMessage('لطفا موضوع پند را بنویسید!');
      return;
    }

    if (_enteredTeller.text.trim().isEmpty) {
      _showMessage('گوینده پند کیست! بنویسید لطفا.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      int? resultId;

      if (widget.initialPand == null) {
        final newPnd = Pand(
          title: _enteredTitle.text,
          sentence: _enteredPand.text,
          category: _selectedCtg,
          teller: _enteredTeller.text,
        );

        resultId = await pndDbs.createPand(newPnd);

        if (resultId == null) {
          throw Exception('create pand failed');
        }
      } else {
        resultId = await pndDbs.updatePand(
          widget.initialPand!,
          _enteredPand.text,
          _enteredTitle.text,
          _enteredTeller.text,
          _selectedCtg,
        );

        if (resultId == null) {
          throw Exception('update pand failed');
        }
      }

      if (mounted) {
        Navigator.of(context).pop(resultId);
      }

      // زمان‌بندی اعلان‌ها نباید پاسخ‌گویی فرم را معطل کند.
      unawaited(NotificationService().ensureAdvanced());
    } on DuplicatePandException {
      _showMessage('این پند قبلاً ثبت شده است.');
    } catch (e) {
      _showMessage('خطا در ذخیره پند! دوباره تلاش کنید');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =====================================================
  // GLASS CARD
  // =====================================================

  Widget glassCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // =====================================================
  // SAVE BUTTON
  // =====================================================

  Widget gradientButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _isLoading ? null : _submitData,
      child: Ink(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff606c55), Color(0xff3a5a40)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff3a5a40).withOpacity(.20),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child:
              _isLoading
                  ? const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                  : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.brown, size: 23),
                      SizedBox(width: 8),
                      Text(
                        'ذخیره پند',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roya',
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialPand != null;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(.35),

        // =================================================
        // APP BAR
        // =================================================
        appBar: AppBar(
          toolbarHeight: 120,
          titleSpacing: 15,
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,

          title: Text(
            isEditing ? 'ویرایش پند' : 'افزودن پند',
            style: const TextStyle(
              fontFamily: 'Roya',
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),

        // =================================================
        // BODY
        // =================================================
        body: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: glassCard(
              Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =====================================
                    // TEXT
                    // =====================================

                    TextField(
                      controller: _enteredPand,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      minLines: 4,
                      maxLines: 7,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(
                        fontFamily: 'Roya',
                        fontSize: 17,
                        height: 1.8,
                        color: Color(0xff3c2201),
                      ),
                      decoration: fieldDecoration(
                        'متن پند',
                        Icons.format_quote_rounded,
                        hintText: 'پند یا سخن مورد نظر را بنویسید...',
                      ),
                    ),

                    const SizedBox(height: 15),

                    // =====================================
                    // TITLE
                    // =====================================
                    TextField(
                      controller: _enteredTitle,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Roya',
                        fontSize: 16,
                        color: Color(0xff3c2201),
                      ),
                      decoration: fieldDecoration(
                        'موضوع',
                        Icons.title_rounded,
                        hintText: 'موضوع یا عنوان پند...',
                      ),
                    ),

                    const SizedBox(height: 15),

                    // =====================================
                    // TELLER
                    // =====================================
                    TextField(
                      controller: _enteredTeller,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Roya',
                        fontSize: 16,
                        color: Color(0xff3c2201),
                      ),
                      decoration: fieldDecoration(
                        'گوینده',
                        Icons.person_outline_rounded,
                        hintText: 'نام گوینده یا صاحب سخن...',
                      ),
                    ),

                    const SizedBox(height: 15),

                    // =====================================
                    // CATEGORY
                    // =====================================
                    _categorySelector(),

                    const SizedBox(height: 24),

                    // =====================================
                    // SAVE
                    // =====================================
                    gradientButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
