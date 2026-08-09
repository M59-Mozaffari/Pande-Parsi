import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pande_parsi/databases/local_dtb.dart';
import 'package:pande_parsi/databases/supabase_dtb.dart';
import 'package:pande_parsi/models/pand.dart';
import 'package:pande_parsi/widgets/add_pand.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DetailsOfPands extends StatefulWidget {
  const DetailsOfPands({super.key, required this.pnd});
  final Pand pnd;

  @override
  State<DetailsOfPands> createState() => _DetailsOfPandsState();
}

class _DetailsOfPandsState extends State<DetailsOfPands> {
  final localDtb = LocalDtb.instance;
  final supabaseDtb = SupabaseDtb();
  bool _isVerifying = false;
  String _errorMsg = '';
  final TextEditingController _pssController = TextEditingController();
  bool _isActive = false;
  late bool _isFavorite;
  bool _stateOfDlg = false;

  @override
  void initState() {
    _isFavorite = widget.pnd.isFavorite;
    super.initState();
  }

  @override
  void dispose() {
    _pssController.dispose();
    super.dispose();
  }

  void _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    final updatedPand = widget.pnd..isFavorite = _isFavorite;
    await localDtb.updatePand(updatedPand);

    if (!_isFavorite) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xff606c55),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'پند موردعلاقه شما از لیست علاقه‌مندی‌ها حذف شد.',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              Icon(Icons.favorite_border, color: Colors.white),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xff606c55),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'پند موردعلاقه شما به لیست علاقه‌مندی‌ها افزوده شد.',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              Icon(Icons.favorite, color: Colors.white),
            ],
          ),
        ),
      );
    }
  }

  void _editPand(BuildContext context) async {
    final updatedId = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (ctx) => AddPand(initialPand: widget.pnd)),
    );

    if (updatedId != null && mounted) {
      Navigator.pop(context, updatedId);
    }
  }

  void _removePand() async {
    await supabaseDtb.deletePand(widget.pnd);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'پند حذف شد!',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Color(0xff606c55),
      ),
    );
    Navigator.pop(context);
  }

  Future<bool> _verifyingPassword(String password) async {
    setState(() {
      _isVerifying = true;
      _errorMsg = '';
    });

    try {
      final response = await supabaseDtb.verifyAccessCode(password);
      return response;
    } catch (e) {
      setState(() {
        _errorMsg = 'خطا در ارتباط با سرور!';
      });
      return false;
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _showAccessDialog(bool isSuccess) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            content: Text(
              isSuccess
                  ? 'دسترسی فعال شد!'
                  : _errorMsg.isNotEmpty
                  ? _errorMsg
                  : 'رمز واردشده معتبر نیست!',
              style: TextStyle(fontFamily: 'Nazanin', fontSize: 24),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'تایید',
                  style: TextStyle(
                    fontFamily: 'Nazanin',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _sharePand() async {
    final textToShare = '''${widget.pnd.sentence}
    -${widget.pnd.teller}

    «ارسال شده از اپلیکیشن پند پارسی»
    ''';

    await Share.share(textToShare);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset('assets/images/hasheeye.png', fit: BoxFit.cover),
        if (!_stateOfDlg)
          Positioned(
            left: 5,
            bottom: 50,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xff8b7141),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(7),
                ),
              ),
              child: Text(
                widget.pnd.title,
                style: TextStyle(
                  fontFamily: 'Roya',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        Container(
          alignment: Alignment.topCenter,
          margin: EdgeInsets.all(18),
          child:
              _stateOfDlg
                  ? Column(
                    children: [
                      Text(
                        'حذف و اصلاح پندها انحصاری است. رمز را برای دسترسی وارد کنید. در صورت نداشتن، با ما به تماس شوید. آدرس ارتباطی در صفحه «درباره ما» ',
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontFamily: 'Zar', fontSize: 18),
                      ),
                      SizedBox(height: 18),
                      Row(
                        children: [
                          _isVerifying
                              ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : IconButton(
                                icon: Icon(
                                  FontAwesomeIcons.tableCellsRowUnlock,
                                  color: Color(0xff60492b),
                                ),
                                onPressed:
                                    _isVerifying
                                        ? null
                                        : () async {
                                          if (_pssController.text
                                              .trim()
                                              .isEmpty) {
                                            setState(() {
                                              _errorMsg =
                                                  'لطفا رمز را وارد کنید';
                                            });
                                            return;
                                          }
                                          final isValid =
                                              await _verifyingPassword(
                                                _pssController.text,
                                              );

                                          setState(() => _isActive = isValid);
                                          _showAccessDialog(isValid);
                                          if (isValid) _pssController.clear();
                                        },
                              ),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: TextField(
                                controller: _pssController,
                                textAlign: TextAlign.right,
                                // textDirection: TextDirection.rtl,
                                decoration: InputDecoration(
                                  labelText: 'رمز دسترسی',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                autocorrect: false,
                                obscureText: true,
                                // obscureText: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                  : Column(
                    children: [
                      Text(
                        widget.pnd.sentence,
                        textAlign: TextAlign.right,
                        maxLines: 5,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Roya',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 9),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '(${persionCtg[widget.pnd.category] ?? widget.pnd.category.name})',
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Roya',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' ${widget.pnd.teller}',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Roya',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      // SizedBox(
                      //   height: 20,
                      //   width: 250,
                      //   child: Image.asset('assets/images/spacer.png'),
                      // ),
                    ],
                  ),
        ),

        Positioned(
          bottom: 8,
          right: 50,
          left: 50,
          child:
              _stateOfDlg
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _stateOfDlg = false;
                              _isActive = false;
                              _pssController.clear();
                            });
                          },
                          icon: Icon(Icons.keyboard_double_arrow_left_outlined),
                        ),
                      ),
                      Flexible(
                        child: IconButton(
                          onPressed: () {
                            if (_isActive) {
                              _editPand(context);
                            }
                          },
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 30,
                            color:
                                _isActive
                                    ? Color(0xff60492b)
                                    : Colors.grey[400],
                          ),
                        ),
                      ),
                      Flexible(
                        child: IconButton(
                          onPressed: () {
                            if (_isActive) {
                              _removePand();
                            }
                          },
                          icon: Icon(
                            Icons.delete_outline,
                            size: 30,
                            color:
                                _isActive
                                    ? Color(0xff60492b)
                                    : Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _stateOfDlg = true;
                            });
                          },
                          icon: Icon(
                            Icons.more_horiz_outlined,
                            size: 30,
                            color: Color(0xff60492b),
                          ),
                        ),
                      ),
                      Flexible(
                        child: IconButton(
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 30,
                          ),
                          color: _isFavorite ? Colors.red : Color(0xff60492b),
                          onPressed: _toggleFavorite,
                        ),
                      ),
                      Flexible(
                        child: IconButton(
                          onPressed: _sharePand,
                          icon: Icon(
                            Icons.share_outlined,
                            size: 30,
                            color: Color(0xff60492b),
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }
}
