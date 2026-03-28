import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import '../services/team_builder.dart';
import '../widgets/fifa_card.dart';

class TeamMakerScreen extends StatefulWidget {
  const TeamMakerScreen({super.key});

  @override
  State<TeamMakerScreen> createState() => _TeamMakerScreenState();
}

class _TeamMakerScreenState extends State<TeamMakerScreen> {
  final _db = DatabaseService();
  List<Player> _allPlayers = [];
  final Set<int> _selectedIds = {};
  List<List<Player>>? _teams;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final players = await _db.getPlayers();
    setState(() => _allPlayers = players);
  }

  void _generateTeams() {
    final selected = _allPlayers.where((p) => _selectedIds.contains(p.id)).toList();
    if (selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 players')),
      );
      return;
    }
    final teams = TeamBuilder.buildTeams(selected);
    setState(() => _teams = teams);
  }

  Future<void> _saveGame() async {
    if (_teams == null) return;
    final team1 = _teams![0];
    final team2 = _teams![1];
    final game = Game(
      team1Players: team1.map((p) => p.id!).join(','),
      team2Players: team2.map((p) => p.id!).join(','),
      date: DateTime.now(),
      isCompleted: false,
    );
    await _db.insertGame(game);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎮 Game saved! Head to Games tab to enter the result.'),
        backgroundColor: Color(0xFF238636),
      ),
    );
    setState(() {
      _teams = null;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('🏟️ Team Maker',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_selectedIds.length} selected',
                  style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: _teams != null ? _buildTeamsView() : _buildSelectionView(),
    );
  }

  Widget _buildSelectionView() {
    if (_allPlayers.isEmpty) {
      return const Center(
        child: Text(
          'Add players first in the Squad tab',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _allPlayers.length,
            itemBuilder: (_, i) {
              final player = _allPlayers[i];
              final selected = _selectedIds.contains(player.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedIds.remove(player.id);
                      } else {
                        _selectedIds.add(player.id!);
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      FifaCard(player: player, isCompact: true),
                      if (selected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF4CAF50), width: 2),
                              color: const Color(0xFF4CAF50).withOpacity(0.15),
                            ),
                            child: const Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(Icons.check_circle,
                                    color: Color(0xFF4CAF50), size: 22),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildMakeTeamsButton(),
      ],
    );
  }

  Widget _buildMakeTeamsButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF161B22),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() {
                if (_selectedIds.length == _allPlayers.length) {
                  _selectedIds.clear();
                } else {
                  _selectedIds.addAll(_allPlayers.map((p) => p.id!));
                }
              }),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _selectedIds.length == _allPlayers.length
                    ? 'Deselect All'
                    : 'Select All',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _selectedIds.length >= 2 ? _generateTeams : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF238636),
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Make Teams (${_selectedIds.length})',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsView() {
    final team1 = _teams![0];
    final team2 = _teams![1];
    final avg1 = TeamBuilder.teamAverage(team1);
    final avg2 = TeamBuilder.teamAverage(team2);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Balance indicator
                _buildBalanceBar(avg1, avg2),
                const SizedBox(height: 20),
                // Teams side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTeamColumn('Team 1', team1, avg1, const Color(0xFF1565C0))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTeamColumn('Team 2', team2, avg2, const Color(0xFFB71C1C))),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF161B22),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _teams = null),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('← Redo', style: TextStyle(color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    '⚽ GAME!',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 16),
                  ),
                ),
              ),
            ],
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
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text('Team Balance',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('$avg1',
                  style: const TextStyle(
                      color: Color(0xFF42A5F5), fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('$avg2',
                  style: const TextStyle(
                      color: Color(0xFFEF5350), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: const Color(0xFFEF5350),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF42A5F5)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamColumn(
      String title, List<Player> team, int avg, Color color) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 15)),
              Text('AVG $avg',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...team.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: FifaCard(player: p, isCompact: true),
            )),
      ],
    );
  }
}