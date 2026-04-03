import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import '../services/team_builder.dart';

class TeamsGamesScreen extends StatefulWidget {
  const TeamsGamesScreen({super.key});

  @override
  State<TeamsGamesScreen> createState() => _TeamsGamesScreenState();
}

class _TeamsGamesScreenState extends State<TeamsGamesScreen> {
  final _db = DatabaseService();

  // Players
  List<Player> _allPlayers = [];
  final Set<int> _selectedIds = {};
  List<List<Player>>? _teams;

  // Games
  List<Game> _games = [];
  Map<int, Player> _playerMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final players = await _db.getPlayers();
    final games = await _db.getGames();
    setState(() {
      _allPlayers = players;
      _games = games;
      _playerMap = {for (final p in players) p.id!: p};
    });
  }

  void _generateTeams() {
    final selected =
        _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();
    if (selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 players')),
      );
      return;
    }
    setState(() => _teams = TeamBuilder.buildTeams(selected));
  }

  Future<void> _saveGame() async {
    if (_teams == null) return;
    final game = Game(
      team1Players: _teams![0].map((p) => p.id!).join(','),
      team2Players: _teams![1].map((p) => p.id!).join(','),
      date: DateTime.now(),
      isCompleted: false,
    );
    final id = await _db.insertGame(game);
    final saved = game.copyWith(id: id);
    setState(() {
      _games.insert(0, saved);
      _teams = null;
      _selectedIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Game saved! Enter the result below.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<Player> _teamPlayers(List<int> ids) =>
      ids.map((id) => _playerMap[id]).whereType<Player>().toList();

  void _openResultDialog(Game game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameResultSheet(
        game: game,
        team1Players: _teamPlayers(game.team1Ids),
        team2Players: _teamPlayers(game.team2Ids),
        onSave: (updated) async {
          await _db.updateGame(updated);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _teams != null ? _buildTeamsView() : _buildMainView(),
      ),
    );
  }

  // ─── Main View (player selection + games list) ───────────────────────────

  Widget _buildMainView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Teams & Games',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
              if (_selectedIds.isNotEmpty)
                Text('${_selectedIds.length} selected',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Player selection section
        if (_allPlayers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text("Today's players",
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    if (_selectedIds.length == _allPlayers.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(_allPlayers.map((p) => p.id!));
                    }
                  }),
                  child: Text(
                    _selectedIds.length == _allPlayers.length
                        ? 'Deselect all'
                        : 'Select all',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _allPlayers.length,
              itemBuilder: (_, i) => _buildPlayerChip(_allPlayers[i]),
            ),
          ),
          const SizedBox(height: 12),
          // Make teams button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedIds.length >= 2 ? _generateTeams : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _selectedIds.isEmpty
                      ? 'Select players to make teams'
                      : 'Make Teams (${_selectedIds.length} players)',
                  style: TextStyle(
                      color: _selectedIds.length >= 2
                          ? Colors.black
                          : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Games header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Games',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('${_games.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Games list
        Expanded(
          child: _games.isEmpty
              ? _buildEmptyGames()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _games.length,
                  itemBuilder: (_, i) => _buildGameCard(_games[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildPlayerChip(Player player) {
    final selected = _selectedIds.contains(player.id);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedIds.remove(player.id);
        } else {
          _selectedIds.add(player.id!);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? Colors.white : Colors.white12,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              player.name,
              style: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
            const SizedBox(width: 6),
            Text(
              '${player.overall}',
              style: TextStyle(
                  color: selected ? Colors.black54 : Colors.white38,
                  fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(Game game) {
    final team1 = _teamPlayers(game.team1Ids);
    final team2 = _teamPlayers(game.team2Ids);
    final potg = _playerMap[game.playerOfGameId];
    final date = game.date;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _openResultDialog(game),
      child: Container(
        height: 130,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF0a0a0a),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Football field background
            _buildFieldBackground(),
            // Bottom info bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    // Game name / score
                    Expanded(
                      child: Text(
                        game.isCompleted
                            ? '${game.team1Score} - ${game.team2Score}'
                            : _gameTitle(team1, team2),
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                    ),
                    if (game.isCompleted)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Game Ended',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    Text(timeStr,
                        style: const TextStyle(
                            color: Colors.black38, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(dateStr,
                        style: const TextStyle(
                            color: Colors.black38, fontSize: 12)),
                  ],
                ),
              ),
            ),
            // POTM badge
            if (potg != null)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('⭐ POTM',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                      Text(potg.name,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            // Pending badge
            if (!game.isCompleted)
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Tap to enter result',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _gameTitle(List<Player> t1, List<Player> t2) {
    if (t1.isEmpty && t2.isEmpty) return 'Game';
    return 'Team 1 vs Team 2';
  }

  Widget _buildFieldBackground() {
    return Positioned.fill(
      child: CustomPaint(painter: _FieldPainter()),
    );
  }

  Widget _buildEmptyGames() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 50, color: Colors.white12),
          SizedBox(height: 10),
          Text('No games yet',
              style: TextStyle(color: Colors.white38, fontSize: 15)),
          SizedBox(height: 4),
          Text('Make teams and press GAME!',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  // ─── Teams View ──────────────────────────────────────────────────────────

  Widget _buildTeamsView() {
    final team1 = _teams![0];
    final team2 = _teams![1];
    final avg1 = TeamBuilder.teamAverage(team1);
    final avg2 = TeamBuilder.teamAverage(team2);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _teams = null),
                child: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text('Teams Ready',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Balance bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildBalanceBar(avg1, avg2),
        ),
        const SizedBox(height: 16),
        // Teams
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _buildTeamCol(
                        'Team 1', team1, avg1, const Color(0xFF1565C0))),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTeamCol(
                        'Team 2', team2, avg2, const Color(0xFFB71C1C))),
              ],
            ),
          ),
        ),
        // GAME! button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                '⚽  GAME!',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceBar(int avg1, int avg2) {
    final total = avg1 + avg2;
    final ratio = total == 0 ? 0.5 : avg1 / total;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Team 1  $avg1',
                  style:
                      const TextStyle(color: Color(0xFF64B5F6), fontSize: 12)),
              const Spacer(),
              Text('$avg2  Team 2',
                  style:
                      const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: const Color(0xFFEF5350),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF42A5F5)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Difference: ${(avg1 - avg2).abs()} OVR',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCol(String title, List<Player> team, int avg, Color color) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800, fontSize: 14)),
              Text('AVG $avg',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...team.map((p) => Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(p.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text('${p.overall}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ─── Field painter ───────────────────────────────────────────────────────────

class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Field green gradient
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1a4a2a), Color(0xFF0d2a16)],
    ).createShader(rect);
    canvas.drawRect(rect, paint);

    // Stripes
    paint.shader = null;
    paint.color = Colors.white.withOpacity(0.03);
    for (int i = 0; i < 6; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(
            Rect.fromLTWH(i * size.width / 6, 0, size.width / 6, size.height),
            paint);
      }
    }

    // Field lines
    paint.color = Colors.white.withOpacity(0.15);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.2;

    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 28, paint);

    // Center line
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);

    // Left goal box
    canvas.drawRect(
        Rect.fromLTWH(
            0, size.height * 0.25, size.width * 0.18, size.height * 0.5),
        paint);

    // Right goal box
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.82, size.height * 0.25, size.width * 0.18,
            size.height * 0.5),
        paint);

    // Outer border
    paint.color = Colors.white.withOpacity(0.2);
    canvas.drawRect(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Game Result Sheet ────────────────────────────────────────────────────────

class GameResultSheet extends StatefulWidget {
  final Game game;
  final List<Player> team1Players;
  final List<Player> team2Players;
  final void Function(Game) onSave;

  const GameResultSheet({
    super.key,
    required this.game,
    required this.team1Players,
    required this.team2Players,
    required this.onSave,
  });

  @override
  State<GameResultSheet> createState() => _GameResultSheetState();
}

class _GameResultSheetState extends State<GameResultSheet> {
  late int _score1;
  late int _score2;
  int? _potgId;

  @override
  void initState() {
    super.initState();
    _score1 = widget.game.team1Score ?? 0;
    _score2 = widget.game.team2Score ?? 0;

    final allIds = {
      ...widget.team1Players.map((p) => p.id),
      ...widget.team2Players.map((p) => p.id),
    };
    // Only keep potgId if it actually exists in the player lists
    _potgId = allIds.contains(widget.game.playerOfGameId)
        ? widget.game.playerOfGameId
        : null;
  }

  void _save() {
    int winner;
    if (_score1 > _score2) {
      winner = 1;
    } else if (_score2 > _score1) {
      winner = 2;
    } else {
      winner = 0;
    }
    widget.onSave(widget.game.copyWith(
      team1Score: _score1,
      team2Score: _score2,
      winnerTeam: winner,
      playerOfGameId: _potgId,
      isCompleted: true,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final seen = <int>{};
    final all = [...widget.team1Players, ...widget.team2Players]
        .where((p) => seen.add(p.id!))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Enter Result',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          // Score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _scoreBox('Team 1', _score1, (v) => setState(() => _score1 = v)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('—',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 24,
                        fontWeight: FontWeight.w300)),
              ),
              _scoreBox('Team 2', _score2, (v) => setState(() => _score2 = v)),
            ],
          ),
          const SizedBox(height: 24),
          // POTG
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('⭐  Player of the Game',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            value: _potgId,
            dropdownColor: const Color(0xFF2C2C2E),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('— None —')),
              ...all.map(
                  (p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
            ],
            onChanged: (v) => setState(() => _potgId = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Result',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(String label, int value, void Function(int) onChange) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: value > 0 ? () => onChange(value - 1) : null,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.remove, color: Colors.white70, size: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('$value',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900)),
            ),
            GestureDetector(
              onTap: () => onChange(value + 1),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white70, size: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
