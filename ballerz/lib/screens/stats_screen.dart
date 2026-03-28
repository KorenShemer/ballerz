import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../services/database_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  late TabController _tabController;

  List<Game> _games = [];
  List<Player> _players = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final games = await _db.getGames();
    final players = await _db.getPlayers();
    setState(() {
      _games = games.where((g) => g.isCompleted).toList();
      _players = players;
    });
  }

  // ─── Stats calculations ──────────────────────────────────────────────────

  Map<int, int> get _winsPerPlayer {
    final wins = <int, int>{};
    for (final g in _games) {
      final winnerIds = g.winnerTeam == 1
          ? g.team1Ids
          : g.winnerTeam == 2
              ? g.team2Ids
              : [];
      for (final id in winnerIds) {
        wins[id] = (wins[id] ?? 0) + 1;
      }
    }
    return wins;
  }

  Map<int, int> get _gamesPerPlayer {
    final counts = <int, int>{};
    for (final g in _games) {
      for (final id in [...g.team1Ids, ...g.team2Ids]) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<int, int> get _potgPerPlayer {
    final counts = <int, int>{};
    for (final g in _games) {
      if (g.playerOfGameId != null) {
        counts[g.playerOfGameId!] = (counts[g.playerOfGameId!] ?? 0) + 1;
      }
    }
    return counts;
  }

  // ─── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('📊 Stats',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4CAF50),
          unselectedLabelColor: Colors.white38,
          indicatorColor: const Color(0xFF4CAF50),
          tabs: const [
            Tab(text: '🏆 Wins'),
            Tab(text: '⭐ POTG'),
            Tab(text: '🎮 Games'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSummaryRow(),
          Expanded(
            child: _games.isEmpty && _players.isEmpty
                ? _buildEmpty()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLeaderboard(_winsPerPlayer, 'Wins',
                          Icons.emoji_events, const Color(0xFFFFD700)),
                      _buildLeaderboard(_potgPerPlayer, 'POTG Awards',
                          Icons.star, const Color(0xFFFFA726)),
                      _buildLeaderboard(_gamesPerPlayer, 'Games Played',
                          Icons.sports_soccer, const Color(0xFF42A5F5)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final totalGoals = _games.fold(
        0, (sum, g) => sum + (g.team1Score ?? 0) + (g.team2Score ?? 0));
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryTile('${_games.length}', 'Games Played'),
          _divider(),
          _summaryTile('${_players.length}', 'Players'),
          _divider(),
          _summaryTile('$totalGoals', 'Total Goals'),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 30, width: 1, color: Colors.white12);

  Widget _summaryTile(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _buildLeaderboard(
      Map<int, int> data, String metric, IconData icon, Color color) {
    if (_players.isEmpty) return _buildEmpty();

    final sorted = _players.map((p) => MapEntry(p, data[p.id] ?? 0)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final entry = sorted[i];
        final player = entry.key;
        final count = entry.value;
        final gamesPlayed = _gamesPerPlayer[player.id] ?? 0;
        final winRate = gamesPlayed > 0
            ? ((_winsPerPlayer[player.id] ?? 0) / gamesPlayed * 100).round()
            : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: i == 0 && count > 0
                  ? color.withOpacity(0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: _buildRankBadge(i, count, color),
            title: Text(
              player.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${player.position} · OVR ${player.overall} · Win rate $winRate%',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                      color: color, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int index, int count, Color color) {
    String rank;
    Color rankColor;
    if (index == 0 && count > 0) {
      rank = '🥇';
      rankColor = const Color(0xFFFFD700);
    } else if (index == 1 && count > 0) {
      rank = '🥈';
      rankColor = const Color(0xFFC0C0C0);
    } else if (index == 2 && count > 0) {
      rank = '🥉';
      rankColor = const Color(0xFFCD7F32);
    } else {
      rank = '${index + 1}';
      rankColor = Colors.white38;
    }

    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          rank,
          style: TextStyle(
              fontSize: index < 3 && count > 0 ? 20 : 14,
              color: rankColor,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 72, color: Colors.white24),
          SizedBox(height: 16),
          Text('No stats yet',
              style: TextStyle(color: Colors.white54, fontSize: 18)),
          SizedBox(height: 8),
          Text('Play some games to see the leaderboard!',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}
