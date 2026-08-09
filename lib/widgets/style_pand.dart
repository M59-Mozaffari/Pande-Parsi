import 'package:flutter/material.dart';
import 'package:pande_parsi/models/pand.dart';
import 'package:pande_parsi/screens/pands_screen.dart';
import './details_of_pands.dart';

class StylePand extends StatelessWidget {
  final Pand pnd;
  const StylePand({super.key, required this.pnd});

  void _showDetailesPand(BuildContext context) async {
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
            content: DetailsOfPands(pnd: pnd),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showDetailesPand(context);
      },
      child: Column(
        children: [
          Text(
            pnd.sentence,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Roya',
              fontWeight: FontWeight.bold,
              fontSize: 21,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              pnd.teller,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Roya',
                fontStyle: FontStyle.italic,
                fontSize: 18,
              ),
            ),
          ),
          Image.asset('assets/images/spacer.png'),
        ],
      ),
    );
  }
}
