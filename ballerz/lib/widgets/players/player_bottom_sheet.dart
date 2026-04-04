import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/player.dart';
import '../../theme/app_colors.dart';

class PlayerBottomSheet extends StatefulWidget {
  final Player? player;
  final void Function(Player) onSave;

  const PlayerBottomSheet({super.key, this.player, required this.onSave});

  @override
  State<PlayerBottomSheet> createState() => _PlayerBottomSheetState();
}

class _PlayerBottomSheetState extends State<PlayerBottomSheet> {
  final _nameController = TextEditingController();
  String? _photoPath;
  String _position = 'ST';
  late Map<String, double> _stats;

  static const _positions = [
    'GK', 'CB', 'LB', 'RB', 'CDM', 'CM', 'CAM', 'LW', 'RW', 'ST'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.player;
    _nameController.text = p?.name ?? '';
    _position  = p?.position ?? 'ST';
    _photoPath = p?.photoPath;
    _stats = {
      'PAC': (p?.pace      ?? 70).toDouble(),
      'SHO': (p?.shooting  ?? 70).toDouble(),
      'PAS': (p?.passing   ?? 70).toDouble(),
      'DRI': (p?.dribbling ?? 70).toDouble(),
      'DEF': (p?.defending ?? 70).toDouble(),
      'PHY': (p?.physical  ?? 70).toDouble(),
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    widget.onSave(Player(
      id:        widget.player?.id,
      name:      _nameController.text.trim(),
      position:  _position,
      pace:      _stats['PAC']!.round(),
      shooting:  _stats['SHO']!.round(),
      passing:   _stats['PAS']!.round(),
      dribbling: _stats['DRI']!.round(),
      defending: _stats['DEF']!.round(),
      physical:  _stats['PHY']!.round(),
      photoPath: _photoPath,
    ));
    Navigator.pop(context);
  }

  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2))),
          _photoOption(icon: Icons.camera_alt_rounded, label: 'Take a photo',
              onTap: () async {
                Navigator.pop(context);
                final x = await ImagePicker()
                    .pickImage(source: ImageSource.camera, imageQuality: 85);
                if (x != null) setState(() => _photoPath = x.path);
              }),
          _photoOption(icon: Icons.photo_library_rounded, label: 'Choose from gallery',
              onTap: () async {
                Navigator.pop(context);
                final x = await ImagePicker()
                    .pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (x != null) setState(() => _photoPath = x.path);
              }),
          if (_photoPath != null)
            _photoOption(icon: Icons.delete_rounded, label: 'Remove photo',
                color: AppColors.danger, onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _photoOption({
    required IconData icon, required String label,
    required VoidCallback onTap, Color color = AppColors.textMain,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: color == AppColors.textMain
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.danger.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: color == AppColors.textMain ? AppColors.primary : AppColors.danger,
            size: 20),
      ),
      title: Text(label, style: TextStyle(
          color: color, fontWeight: FontWeight.w500, fontSize: 15)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final overall = (_stats.values.fold(0.0, (a, b) => a + b) / 6).round();

    return Container(
      decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)))),
            // ── Title + photo picker ────────────────────────────────────
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(widget.player == null ? 'New Player' : 'Edit Player',
                    style: const TextStyle(color: AppColors.textMain, fontSize: 22,
                        fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(widget.player == null
                        ? 'Fill in the details below' : 'Update player info',
                    style: const TextStyle(color: AppColors.textSub, fontSize: 13)),
              ])),
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                      image: _photoPath != null
                          ? DecorationImage(image: FileImage(File(_photoPath!)),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: _photoPath == null
                        ? const Icon(Icons.person_rounded,
                            color: AppColors.primary, size: 30)
                        : null,
                  ),
                  Positioned(bottom: 0, right: 0,
                    child: Container(padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 12))),
                ]),
              ),
            ]),
            const SizedBox(height: 24),
            // ── Name + position ─────────────────────────────────────────
            Row(children: [
              Expanded(flex: 3, child: _field(child: TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textMain,
                    fontWeight: FontWeight.w500, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Player name',
                  hintStyle: TextStyle(color: AppColors.textSub),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      color: AppColors.textSub, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ))),
              const SizedBox(width: 10),
              Expanded(flex: 1, child: _field(child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _position, dropdownColor: AppColors.surface,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSub, size: 20),
                  style: const TextStyle(color: AppColors.textMain,
                      fontWeight: FontWeight.bold, fontSize: 15),
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  items: _positions.map((p) => DropdownMenuItem(
                      value: p, child: Text(p, style: const TextStyle(
                          color: AppColors.textMain)))).toList(),
                  onChanged: (v) => setState(() => _position = v!),
                ),
              ))),
            ]),
            const SizedBox(height: 20),
            // ── Attributes sliders ──────────────────────────────────────
            Row(children: [
              const Text('Attributes', style: TextStyle(
                  color: AppColors.textMain, fontSize: 17, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('OVR  $overall', style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w900,
                    fontSize: 14)),
              ),
            ]),
            const SizedBox(height: 12),
            ..._stats.entries.map((e) => _buildSlider(e.key, e.value)),
            const SizedBox(height: 28),
            // ── Buttons ─────────────────────────────────────────────────
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: AppColors.divider, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cancel', style: TextStyle(
                    color: AppColors.textSub, fontWeight: FontWeight.w600,
                    fontSize: 15)),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Player', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _field({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }

  Widget _buildSlider(String label, double value) {
    final pct   = (value - 1) / 98;
    final color = Color.lerp(const Color(0xFF3D5A6B), AppColors.primary, pct)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 38, child: Text(label, style: const TextStyle(
            color: AppColors.textSub, fontSize: 12,
            fontWeight: FontWeight.w700, letterSpacing: 0.3))),
        Expanded(child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color, inactiveTrackColor: AppColors.divider,
            thumbColor: color, trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            overlayColor: AppColors.primary.withOpacity(0.12),
          ),
          child: Slider(value: value, min: 1, max: 99,
              onChanged: (v) => setState(() => _stats[label] = v)),
        )),
        SizedBox(width: 32, child: Text('${value.round()}',
            style: TextStyle(color: color, fontSize: 14,
                fontWeight: FontWeight.w800),
            textAlign: TextAlign.right)),
      ]),
    );
  }
}