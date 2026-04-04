import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class FilterChip {
  final String id;
  final String label;
  final Color color;
  const FilterChip({required this.id, required this.label, required this.color});
}

// ── Pinned sliver delegate ────────────────────────────────────────────────────
class PinnedFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const PinnedFilterBarDelegate({required this.child});

  static const double height = 52.0;

  @override double get maxExtent => height;
  @override double get minExtent => height;

  @override
  bool shouldRebuild(PinnedFilterBarDelegate old) => child != old.child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: height, child: child);
  }
}

// ── Filter bar widget ─────────────────────────────────────────────────────────
class PlayersFilterBar extends StatelessWidget {
  final List<FilterChip> chips;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const PlayersFilterBar({
    super.key,
    required this.chips,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: chips.map((c) => _Chip(
            chip: c,
            selected: c.id == selectedId,
            onTap: () => onSelected(c.id),
          )).toList(),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final FilterChip chip;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.chip, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? chip.color.withOpacity(0.18) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chip.color : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          chip.label,
          style: TextStyle(
            color: selected ? chip.color : AppColors.textSub,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}