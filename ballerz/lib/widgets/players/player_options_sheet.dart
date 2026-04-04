import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../theme/app_colors.dart';
import 'player_row.dart' show posColor;

void showPlayerOptionsSheet({
  required BuildContext context,
  required Player player,
  required bool isTotw,
  required VoidCallback onEdit,
  required VoidCallback onViewCard,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
                color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              // ── Player header ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: posColor(player.position).withOpacity(0.18),
                      image: player.photoPath != null
                          ? DecorationImage(
                              image: FileImage(File(player.photoPath!)),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: player.photoPath == null
                        ? Center(child: Text(player.name[0].toUpperCase(),
                            style: TextStyle(
                                color: posColor(player.position),
                                fontWeight: FontWeight.bold, fontSize: 16)))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(player.name, style: const TextStyle(
                        color: AppColors.textMain, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${player.position}  ·  OVR ${player.overall}',
                        style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
                  ]),
                  const Spacer(),
                  if (isTotw)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black, borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE8C96D), width: 1),
                      ),
                      child: const Text('TOTW', style: TextStyle(
                          color: Color(0xFFE8C96D), fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                ]),
              ),
              const Divider(height: 0, thickness: 0.5, color: AppColors.divider),
              _OptionTile(icon: Icons.edit_rounded, iconColor: AppColors.primary,
                  label: 'Edit Player', onTap: onEdit),
              const Divider(height: 0, thickness: 0.5, color: AppColors.divider, indent: 56),
              _OptionTile(icon: Icons.style_rounded, iconColor: Color(0xFFE8A800),
                  label: 'View FIFA Card', onTap: onViewCard),
              const Divider(height: 0, thickness: 0.5, color: AppColors.divider, indent: 56),
              _OptionTile(icon: Icons.delete_outline_rounded, iconColor: AppColors.danger,
                  label: 'Remove Player', textColor: AppColors.danger, onTap: onDelete),
            ]),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('Cancel', style: TextStyle(
                  color: AppColors.textMain, fontWeight: FontWeight.w600, fontSize: 16))),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final Color textColor;

  const _OptionTile({
    required this.icon, required this.iconColor,
    required this.label, required this.onTap,
    this.textColor = AppColors.textMain,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(
              color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
          const Spacer(),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textSub.withOpacity(0.5), size: 20),
        ]),
      ),
    );
  }
}