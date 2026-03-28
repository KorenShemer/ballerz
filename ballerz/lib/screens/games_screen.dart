import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../services/database_service.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final _db = DatabaseService();
  List<Game> _games = [];
  Map<int, Player> _playerMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final games = await _db.getGames();
    final players = await _db.getPlayers();
    setState(() {
      _games = games;
      _playerMap = {for (final p in players) p.id!: p};
    });
  }

  List<Player> _teamPlayers(List<int> ids) =>
      ids.map((id) => _playerMap[id]).whereType<Player>().toList();

  void _openResultDialog(Game game) {
    showDialog(
      context: context,
      builder: (_) => GameResultDialog(
        game: game,
        playerMap: _playerMap,
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
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('🎮 Games',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_games.length} games',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: _games.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _games.length,
              itemBuilder: (_, i) => _buildGameCard(_games[i]),
            ),
    );
  }

  Widget _buildGameCard(Game game) {
    final team1 = _teamPlayers(game.team1Ids);
    final team2 = _teamPlayers(game.team2Ids);
    final potg = _playerMap[game.playerOfGameId];
    final dateStr =
        '${game.date.day}/${game.date.month}/${game.date.year}  ${game.date.hour.toString().padLeft(2, '0')}:${game.date.minute.toString().padLeft(2, '0')}';

    return Card(
      color: const Color(0xFF161B22),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: game.isCompleted ? Colors.white12 : const Color(0xFFFFD700).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openResultDialog(game),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Date + status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateStr,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: game.isCompleted
                          ? Colors.white12
                          : const Color(0xFFFFD700).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      game.isCompleted ? 'Completed' : 'Pending',
                      style: TextStyle(
                        color: game.isCompleted
                            ? Colors.white38
                            : const Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Score row
              Row(
                children: [
                  Expanded(child: _buildTeamSide(team1, 1, game)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: game.isCompleted
                        ? Text(
                            '${game.team1Score} - ${game.team2Score}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : const Text(
                            'vs',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                  Expanded(child: _buildTeamSide(team2, 2, game)),
                ],
              ),
              // POTG
              if (potg != null) ...[
                const Divider(color: Colors.white12, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Player of the Game: ${potg.name}',
                      style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
              if (!game.isCompleted) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _openResultDialog(game),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFD700)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Enter Result',
                        style: TextStyle(color: Color(0xFFFFD700))),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSide(List<Player> team, int teamNum, Game game) {
    final isWinner =
        game.isCompleted && game.winnerTeam == teamNum;
    return Column(
      crossAxisAlignment:
          teamNum == 1 ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: teamNum == 1
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            if (isWinner && teamNum == 2)
              const Icon(Icons.emoji_events,
                  color: Color(0xFFFFD700), size: 14),
            Text(
              'Team $teamNum',
              style: TextStyle(
                color: isWinner ? const Color(0xFFFFD700) : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (isWinner && teamNum == 1)
              const Icon(Icons.emoji_events,
                  color: Color(0xFFFFD700), size: 14),
          ],
        ),
        ...team.map((p) => Text(
              p.name,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            )),
      ],
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 72, color: Colors.white24),
          SizedBox(height: 16),
          Text('No games yet',
              style: TextStyle(color: Colors.white54, fontSize: 18)),
          SizedBox(height: 8),
          Text('Make teams and press GAME! to get started',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Game Result Dialog ───────────────────────────────────────────────────────

class GameResultDialog extends StatefulWidget {
  final Game game;
  final Map<int, Player> playerMap;
  final List<Player> team1Players;
  final List<Player> team2Players;
  final void Function(Game) onSave;

  const GameResultDialog({
    super.key,
    required this.game,
    required this.playerMap,
    required this.team1Players,
    required this.team2Players,
    required this.onSave,
  });

  @override
  State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog> {
  late int _score1;
  late int _score2;
  int? _potgId;

  @override
  void initState() {
    super.initState();
    _score1 = widget.game.team1Score ?? 0;
    _score2 = widget.game.team2Score ?? 0;
    _potgId = widget.game.playerOfGameId;
  }

  void _save() {
    int? winner;
    if (_score1 > _score2) {
      winner = 1;
    } else if (_score2 > _score1) {
      winner = 2;
    } else {
      winner = 0; // draw
    }
    final updated = widget.game.copyWith(
      team1Score: _score1,
      team2Score: _score2,
      winnerTeam: winner,
      playerOfGameId: _potgId,
      isCompleted: true,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allPlayers = [...widget.team1Players, ...widget.team2Players];

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter Result',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Score input
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scoreInput('Team 1', _score1, (v) => setState(() => _score1 = v)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(' - ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900)),
                ),
                _scoreInput('Team 2', _score2, (v) => setState(() => _score2 = v)),
              ],
            ),
            const SizedBox(height: 24),
            // POTG
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('⭐ Player of the Game',
                  style: TextStyle(
                      color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _potgId,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— None —')),
                ...allPlayers.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name),
                    )),
              ],
              onChanged: (v) => setState(() => _potgId = v),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save Result',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreInput(String label, int value, void Function(int) onChanged) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Text('$value',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}