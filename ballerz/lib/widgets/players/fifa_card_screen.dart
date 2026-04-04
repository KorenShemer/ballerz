import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/player.dart';

class FifaCardScreen extends StatelessWidget {
  final Player player;
  final bool isTotw;
  const FifaCardScreen({super.key, required this.player, required this.isTotw});

  String get _cardAsset {
    if (isTotw) return 'assets/cards/totw_card.png';
    if (player.overall >= 80) return 'assets/cards/gold_card.png';
    if (player.overall >= 70) return 'assets/cards/silver_card.png';
    return 'assets/cards/bronze_card.png';
  }

  Color get _textColor {
    if (isTotw) return const Color(0xFFE8C96D);
    if (player.overall >= 80) return const Color.fromARGB(255, 39, 26, 0);
    if (player.overall >= 70) return const Color(0xFF2C2C2C);
    return const Color(0xFF4A2800);
  }

  Color get _subTextColor {
    if (isTotw) return const Color(0xFFD4A843);
    if (player.overall >= 80) return const Color.fromARGB(255, 39, 26, 0);
    if (player.overall >= 70) return const Color(0xFF4A4A4A);
    return const Color(0xFF6B3C10);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: 260, height: 360,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(child: Image.asset(_cardAsset, fit: BoxFit.fill)),
                _buildContent(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: isTotw
              ? const EdgeInsets.only(left: 28, top: 70)
              : const EdgeInsets.only(left: 22, top: 80),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text('${player.overall}', style: TextStyle(
                fontFamily: 'EACondMedium', color: _textColor,
                fontSize: 34, fontWeight: FontWeight.w700, height: 1)),
            Text(player.position, style: TextStyle(
                fontFamily: 'EACondBold', color: _textColor,
                fontSize: 15, fontWeight: FontWeight.w900,
                letterSpacing: 1.5, height: 1)),
          ]),
        ),
        SizedBox(height: 86, child: Center(
          child: player.photoPath != null
              ? OverflowBox(
                  maxHeight: 140, alignment: Alignment.bottomCenter,
                  child: ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      stops: isTotw ? const [0.6, 1.0] : const [1.0, 1.0],
                      colors: const [Colors.white, Colors.transparent],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.file(File(player.photoPath!),
                        width: 200, height: 260, fit: BoxFit.contain),
                  ))
              : Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _textColor.withOpacity(0.15),
                    border: Border.all(color: _textColor.withOpacity(0.3), width: 2),
                  ),
                  child: Center(child: Text(player.name[0].toUpperCase(),
                      style: TextStyle(color: _textColor, fontSize: 48,
                          fontWeight: FontWeight.w900)))),
        )),
        if (isTotw) const SizedBox(height: 20) else const SizedBox(height: 8),
        Center(child: Text(player.name.toUpperCase(),
            style: TextStyle(fontFamily: 'EACondBold', color: _textColor,
                fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
            overflow: TextOverflow.ellipsis)),
        Padding(
          padding: isTotw
              ? const EdgeInsets.symmetric(horizontal: 24)
              : const EdgeInsets.symmetric(horizontal: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _stat('PAC', player.pace), _stat('SHO', player.shooting),
            _stat('PAS', player.passing), _stat('DRI', player.dribbling),
            _stat('DEF', player.defending), _stat('PHY', player.physical),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(String label, int value) {
    return Column(children: [
      Text(label, style: TextStyle(fontFamily: 'EACondMedium', color: _subTextColor,
          fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
      Text('$value', style: TextStyle(fontFamily: 'EACondMedium', color: _textColor,
          fontSize: 21, fontWeight: FontWeight.w700)),
    ]);
  }
}