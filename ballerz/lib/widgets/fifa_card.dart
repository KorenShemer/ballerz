import 'package:flutter/material.dart';
import '../models/player.dart';

class FifaCard extends StatelessWidget {
  final Player player;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FifaCard({
    super.key,
    required this.player,
    this.isCompact = false,
    this.onTap,
    this.onLongPress,
  });

  Color get _cardColor {
    final o = player.overall;
    if (o >= 85) return const Color(0xFFFFD700); // Gold
    if (o >= 75) return const Color(0xFFC0C0C0); // Silver
    return const Color(0xFFCD7F32); // Bronze
  }

  Color get _cardDark {
    final o = player.overall;
    if (o >= 85) return const Color(0xFFB8860B);
    if (o >= 75) return const Color(0xFF808080);
    return const Color(0xFF8B4513);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: isCompact ? _buildCompact() : _buildFull(),
    );
  }

  Widget _buildFull() {
    return Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardColor, _cardDark],
        ),
        boxShadow: [
          BoxShadow(
            color: _cardColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Overall + Position
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${player.overall}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        height: 1,
                      ),
                    ),
                    Text(
                      player.position,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                // Player avatar placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black26,
                    border: Border.all(color: Colors.black38, width: 1.5),
                  ),
                  child: const Icon(Icons.person, size: 30, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Player name
            Text(
              player.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            const Divider(color: Colors.black38, height: 12, thickness: 0.8),
            // Stats grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statColumn([
                  _statItem('PAC', player.pace),
                  _statItem('SHO', player.shooting),
                  _statItem('PAS', player.passing),
                ]),
                _statColumn([
                  _statItem('DRI', player.dribbling),
                  _statItem('DEF', player.defending),
                  _statItem('PHY', player.physical),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [_cardColor.withOpacity(0.85), _cardDark.withOpacity(0.85)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(
              '${player.overall}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              player.position,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                player.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _statItem(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            '$value ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}