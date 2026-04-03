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
  Map<int, Player> _playerMap = {};

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
      _playerMap = {for (final p in players) p.id!: p};
    });
  }

  Map<int, int> get _wins {
    final m = <int, int>{};
    for (final g in _games) {
      final ids = g.winnerTeam == 1
          ? g.team1Ids
          : g.winnerTeam == 2
              ? g.team2Ids
              : <int>[];
      for (final id in ids) m[id] = (m[id] ?? 0) + 1;
    }
    return m;
  }

  Map<int, int> get _gamesPlayed {
    final m = <int, int>{};
    for (final g in _games) {
      for (final id in [...g.team1Ids, ...g.team2Ids]) {
        m[id] = (m[id] ?? 0) + 1;
      }
    }
    return m;
  }

  Map<int, int> get _potg {
    final m = <int, int>{};
    for (final g in _games) {
      if (g.playerOfGameId != null) {
        m[g.playerOfGameId!] = (m[g.playerOfGameId!] ?? 0) + 1;
      }
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text('Stats',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
            _buildSummary(),
            const SizedBox(height: 4),
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: '🏆 Wins'),
                Tab(text: '⭐ POTG'),
                Tab(text: '🎮 Played'),
              ],
            ),
            Expanded(
              child: _players.isEmpty
                  ? _buildEmpty()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBoard(_wins, 'Wins'),
                        _buildBoard(_potg, 'POTG'),
                        _buildBoard(_gamesPlayed, 'Games'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final totalGoals = _games.fold(
        0, (s, g) => s + (g.team1Score ?? 0) + (g.team2Score ?? 0));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statPill('${_games.length}', 'Games'),
          const SizedBox(width: 8),
          _statPill('${_players.length}', 'Players'),
          const SizedBox(width: 8),
          _statPill('$totalGoals', 'Goals'),
        ],
      ),
    );
  }

  Widget _statPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBoard(Map<int, int> data, String metric) {
    final sorted = List<MapEntry<Player, int>>.from(
      _players.map((p) => MapEntry(p, data[p.id] ?? 0)),
    )..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final player = sorted[i].key;
        final count = sorted[i].value;
        final played = _gamesPlayed[player.id] ?? 0;
        final winRate = played > 0
            ? ((_wins[player.id] ?? 0) / played * 100).round()
            : 0;

        return Container(
          height: 64,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(14),
            border: i == 0 && count > 0
                ? Border.all(color: Colors.white24, width: 1)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 28,
                  child: Text(
                    i == 0 && count > 0
                        ? '🥇'
                        : i == 1 && count > 0
                            ? '🥈'
                            : i == 2 && count > 0
                                ? '🥉'
                                : '${i + 1}',
                    style: TextStyle(
                      fontSize: i < 3 && count > 0 ? 18 : 13,
                      color: Colors.white38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),
                // Info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                      Text(
                          '${player.position}  ·  OVR ${player.overall}  ·  ${winRate}% wins',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                // Count
                Text('$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 60, color: Colors.white12),
          SizedBox(height: 12),
          Text('No stats yet',
              style: TextStyle(color: Colors.white38, fontSize: 16)),
          SizedBox(height: 6),
          Text('Play games to see the leaderboard',
              style: TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }
}