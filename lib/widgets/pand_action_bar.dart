import 'package:flutter/material.dart';

class PandActionBar extends StatelessWidget {
  const PandActionBar({
    super.key,
    required this.isFavorite,
    required this.onFavorite,
    required this.onShare,
    required this.onMore,
  });

  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onMore;

  static const _iconColor = Color(0xffa77d3f);

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = _iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.5),
      child: SizedBox(
        width: 30,
        height: 30,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _iconColor.withAlpha(150), width: 1.3),
          ),
          child: IconButton(
            tooltip: tooltip,
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            icon: Icon(icon, size: 23, color: color),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          tooltip:
              isFavorite ? 'حذف از علاقه‌مندی‌ها' : 'افزودن به علاقه‌مندی‌ها',
          onPressed: onFavorite,
          color: isFavorite ? Colors.red : _iconColor,
        ),
        _actionButton(
          icon: Icons.share_outlined,
          tooltip: 'اشتراک‌گذاری',
          onPressed: onShare,
        ),
        _actionButton(
          icon: Icons.more_horiz_outlined,
          tooltip: 'گزینه‌های بیشتر',
          onPressed: onMore,
        ),
      ],
    );
  }
}
