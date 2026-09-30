import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pande_parsi/databases/local_dtb.dart';
import 'package:pande_parsi/models/pand.dart';
import 'package:pande_parsi/screens/pands_screen.dart';
import './details_of_pands.dart';
import './pand_action_bar.dart';

class StylePand extends StatefulWidget {
  final Pand pnd;
  const StylePand({super.key, required this.pnd});

  @override
  State<StylePand> createState() => _StylePandState();
}

class _StylePandState extends State<StylePand> {
  final localDtb = LocalDtb.instance;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.pnd.isFavorite;
  }

  void _showMoreOptions(BuildContext context) async {
    final editedPandId = await showDialog<int>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Color(0xff8a7249), width: 3),
            ),
            scrollable: true,
            backgroundColor: const Color(0xffe8dbb8),
            content: DetailsOfPands(pnd: widget.pnd, openAccessDialog: true),
          ),
    );

    if (editedPandId != null && context.mounted) {
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => PandsScreen(
                  initialPandId: editedPandId,
                  scrollToPand: true,
                ),
          ),
        );
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
      widget.pnd.isFavorite = _isFavorite;
    });
    await localDtb.updatePand(widget.pnd);
  }

  Future<void> _sharePand() async {
    await Share.share('''${widget.pnd.sentence}
    -${widget.pnd.teller}

    «ارسال شده از اپلیکیشن پند پارسی»''');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.pnd.sentence,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Roya',
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PandActionBar(
              isFavorite: _isFavorite,
              onFavorite: _toggleFavorite,
              onShare: _sharePand,
              onMore: () => _showMoreOptions(context),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 5.0),
                child: Text(
                  widget.pnd.teller,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Roya',
                    fontStyle: FontStyle.italic,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        Image.asset('assets/images/spacer.png'),
      ],
    );
  }
}
