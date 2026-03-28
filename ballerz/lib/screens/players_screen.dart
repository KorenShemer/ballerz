import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/database_service.dart';
import '../widgets/fifa_card.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _db = DatabaseService();
  List<Player> _players = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players = await _db.getPlayers();
    setState(() => _players = players);
  }

  void _openPlayerDialog({Player? player}) {
    showDialog(
      context: context,
      builder: (_) => PlayerDialog(
        player: player,
        onSave: (p) async {
          if (p.id == null) {
            await _db.insertPlayer(p);
          } else {
            await _db.updatePlayer(p);
          }
          _loadPlayers();
        },
      ),
    );
  }

  void _confirmDelete(Player player) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Player', style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove ${player.name} from your squad?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _db.deletePlayer(player.id!);
              Navigator.pop(context);
              _loadPlayers();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('⚽ Squad',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_players.length} players',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: _players.isEmpty
          ? _buildEmpty()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 160 / 220,
                ),
                itemCount: _players.length,
                itemBuilder: (_, i) => FifaCard(
                  player: _players[i],
                  onTap: () => _openPlayerDialog(player: _players[i]),
                  onLongPress: () => _confirmDelete(_players[i]),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPlayerDialog(),
        backgroundColor: const Color(0xFF238636),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Player', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_add, size: 72, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No players yet',
              style: TextStyle(color: Colors.white54, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Tap + to add your first player',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Add / Edit Dialog ────────────────────────────────────────────────────────

class PlayerDialog extends StatefulWidget {
  final Player? player;
  final void Function(Player) onSave;

  const PlayerDialog({super.key, this.player, required this.onSave});

  @override
  State<PlayerDialog> createState() => _PlayerDialogState();
}

class _PlayerDialogState extends State<PlayerDialog> {
  final _nameController = TextEditingController();
  String _position = 'ST';
  late Map<String, double> _stats;

  static const _positions = ['GK', 'CB', 'LB', 'RB', 'CDM', 'CM', 'CAM', 'LW', 'RW', 'ST'];

  @override
  void initState() {
    super.initState();
    final p = widget.player;
    _nameController.text = p?.name ?? '';
    _position = p?.position ?? 'ST';
    _stats = {
      'PAC': (p?.pace ?? 70).toDouble(),
      'SHO': (p?.shooting ?? 70).toDouble(),
      'PAS': (p?.passing ?? 70).toDouble(),
      'DRI': (p?.dribbling ?? 70).toDouble(),
      'DEF': (p?.defending ?? 70).toDouble(),
      'PHY': (p?.physical ?? 70).toDouble(),
    };
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    final player = Player(
      id: widget.player?.id,
      name: _nameController.text.trim(),
      position: _position,
      pace: _stats['PAC']!.round(),
      shooting: _stats['SHO']!.round(),
      passing: _stats['PAS']!.round(),
      dribbling: _stats['DRI']!.round(),
      defending: _stats['DEF']!.round(),
      physical: _stats['PHY']!.round(),
    );
    widget.onSave(player);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final overall = _stats.values.fold(0.0, (a, b) => a + b) ~/ 6;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.player == null ? 'New Player' : 'Edit Player',
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Overall badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              ),
              child: Text(
                'OVR $overall',
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w900,
                    fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            // Name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Player Name',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Position picker
            DropdownButtonFormField<String>(
              value: _position,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Position',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _positions
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _position = v!),
            ),
            const SizedBox(height: 16),
            // Stat sliders
            ..._stats.entries.map((entry) => _buildSlider(entry.key, entry.value)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF238636),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF4CAF50),
                thumbColor: const Color(0xFF4CAF50),
                inactiveTrackColor: Colors.white12,
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value,
                min: 1,
                max: 99,
                onChanged: (v) => setState(() => _stats[label] = v),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              value.round().toString(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}