import 'dart:io';
import 'dart:ui';
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
    if (widget.initialPand != null) {
      _enteredPand.text = widget.initialPand!.sentence;
      _enteredTitle.text = widget.initialPand!.title;
      _enteredTeller.text = widget.initialPand!.teller;
      _selectedCtg = widget.initialPand!.category;
    }
    super.initState();
  }

  @override
  void dispose() {
    _enteredPand.dispose();
    _enteredTitle.dispose();
    _enteredTeller.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withOpacity(.85),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xff606c55), width: 2),
      ),
    );
  }

  void _showMessage(String text, {bool isError = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.redAccent : const Color(0xff606c55),
        behavior: SnackBarBehavior.floating,
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

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _submitData() async {
    /// 🔴 اعتبارسنجی فیلدها
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

    /// 🌐 بررسی اینترنت
    final hasInternet = await _hasInternet();

    if (!hasInternet) {
      _showMessage(
        'شما آفلاین هستید! برای ثبت پند باید به اینترنت متصل باشید.',
      );
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
      } else {
        await pndDbs.updatePand(
          widget.initialPand!,
          _enteredPand.text,
          _enteredTitle.text,
          _enteredTeller.text,
          _selectedCtg,
        );

        resultId = widget.initialPand!.id;
      }

      /// 🔔 آپدیت نوتیف
      await NotificationService().ensureAdvanced();

      if (mounted) {
        Navigator.of(context).pop(resultId);
      }
    } catch (e) {
      _showMessage('خطا در ذخیره پند! دوباره تلاش کنید');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget glassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.75),
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget gradientButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _submitData,
      child: Ink(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff606c55), Color(0xff3a5a40)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child:
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                    'ذخیره پند',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roya',
                      color: Colors.white,
                    ),
                  ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.jpg'),
          fit: BoxFit.cover,
        ),
      ),

      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(.35),

        appBar: AppBar(
          toolbarHeight: 110, // افزایش ارتفاع
          titleSpacing: 10,
          title: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.initialPand == null ? 'افزودن پند' : 'ویرایش پند',
              style: const TextStyle(fontFamily: 'Roya', fontSize: 22),
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),

        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: glassCard(
              Directionality(
                textDirection: TextDirection.rtl,

                child: Column(
                  children: [
                    /// متن پند
                    TextField(
                      controller: _enteredPand,
                      textAlign: TextAlign.right,
                      minLines: 3,
                      maxLines: null,
                      decoration: fieldDecoration(
                        'متن پند',
                        Icons.format_quote,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// موضوع
                    TextField(
                      controller: _enteredTitle,
                      textAlign: TextAlign.right,
                      decoration: fieldDecoration('موضوع', Icons.title),
                    ),

                    const SizedBox(height: 16),

                    /// گوینده
                    TextField(
                      controller: _enteredTeller,
                      textAlign: TextAlign.right,
                      decoration: fieldDecoration('گوینده', Icons.person),
                    ),

                    const SizedBox(height: 16),

                    /// دسته بندی
                    DropdownButtonFormField<Category>(
                      value: _selectedCtg,
                      decoration: fieldDecoration('دسته بندی', Icons.category),

                      alignment: Alignment.centerRight,
                      icon: const Icon(Icons.keyboard_arrow_down),

                      items:
                          Category.values.map((ctg) {
                            return DropdownMenuItem(
                              value: ctg,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  persionCtg[ctg]!,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            );
                          }).toList(),

                      onChanged: (value) {
                        setState(() {
                          _selectedCtg = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    /// دکمه ذخیره
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
