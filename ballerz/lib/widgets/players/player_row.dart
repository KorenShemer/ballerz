import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../theme/app_colors.dart';

// ── Position & OVR colour helpers (shared across widgets) ────────────────────
Color posColor(String pos) {
  switch (pos) {
    case 'GK':  return const Color(0xFFF59E0B);
    case 'CB': case 'LB': case 'RB': return const Color(0xFF3B82F6);
    case 'CDM': case 'CM': return const Color(0xFF8B5CF6);
    case 'CAM': case 'LW': case 'RW': return const Color(0xFFEC4899);
    case 'ST':  return const Color(0xFFEF4444);
    default:    return AppColors.textSub;
  }
}

Color ovrColor(int ovr) {
  if (ovr >= 85) return const Color(0xFF25D366);
  if (ovr >= 75) return const Color(0xFF128C7E);
  if (ovr >= 65) return const Color(0xFF667781);
  return const Color(0xFFAAB7BC);
}

// ── PlayerRow ────────────────────────────────────────────────────────────────
class PlayerRow extends StatelessWidget {
  final Player player;
  final bool isTotw;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PlayerRow({
    super.key,
    required this.player,
    required this.isTotw,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final ovrC = ovrColor(player.overall);
    final posC = posColor(player.position);
    final stats = [
      ('PAC', player.pace), ('SHO', player.shooting), ('PAS', player.passing),
      ('DRI', player.dribbling), ('DEF', player.defending), ('PHY', player.physical),
    ];

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isSelected ? AppColors.primary.withOpacity(0.09) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Selection circle ──────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: selectionMode ? 28 : 0,
              margin: EdgeInsets.only(right: selectionMode ? 10 : 0),
              child: selectionMode
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.textSub,
                            width: 1),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Avatar ────────────────────────────────────────────────────
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTotw ? Colors.black : posC.withOpacity(0.18),
                  border: isTotw
                      ? Border.all(color: const Color(0xFFE8C96D), width: 2)
                      : null,
                  image: player.photoPath != null
                      ? DecorationImage(
                          image: FileImage(File(player.photoPath!)),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: player.photoPath == null
                    ? Center(
                        child: Text(
                          player.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                              color: isTotw ? const Color(0xFFE8C96D) : posC,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ))
                    : null,
              ),
              Positioned(
                bottom: -2, right: -2,
                child: isTotw
                    ? Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black, shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE8C96D), width: 1.5),
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: Color(0xFFE8C96D), size: 10))
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: posC,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.card, width: 1.5),
                        ),
                        child: Text(player.position, style: const TextStyle(
                            color: Colors.white, fontSize: 8,
                            fontWeight: FontWeight.w800, letterSpacing: 0.3))),
              ),
            ]),
            const SizedBox(width: 14),

            // ── Name + stats ──────────────────────────────────────────────
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(player.name,
                        style: const TextStyle(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w600,
                            fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (isTotw) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE8C96D), width: 1),
                      ),
                      child: const Text('TOTW', style: TextStyle(
                          color: Color(0xFFE8C96D), fontSize: 9,
                          fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
                const SizedBox(height: 7),
                Row(children: stats
                    .map((s) => Expanded(child: _StatCell(label: s.$1, value: s.$2)))
                    .toList()),
              ]),
            ),
            const SizedBox(width: 10),

            // ── OVR badge ─────────────────────────────────────────────────
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: isTotw ? Colors.black : ovrC.withOpacity(0.12),
                shape: BoxShape.circle,
                border: isTotw
                    ? Border.all(color: const Color(0xFFE8C96D), width: 1.5)
                    : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${player.overall}', style: TextStyle(
                    color: isTotw ? const Color(0xFFE8C96D) : ovrC,
                    fontWeight: FontWeight.w900, fontSize: 16)),
                Text('OVR', style: TextStyle(
                    color: (isTotw ? const Color(0xFFE8C96D) : ovrC).withOpacity(0.7),
                    fontSize: 6, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat cell ─────────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  final String label;
  final int value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          color: AppColors.textSub, fontSize: 9,
          fontWeight: FontWeight.w700, letterSpacing: 0.4)),
      const SizedBox(height: 1),
      Text('$value', style: const TextStyle(
          color: AppColors.textMain, fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }
}