import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import '../services/team_builder.dart';
import '../theme/app_colors.dart';

class TeamsGamesScreen extends StatefulWidget {
  const TeamsGamesScreen({super.key});

  @override
  State<TeamsGamesScreen> createState() => _TeamsGamesScreenState();
}

class _TeamsGamesScreenState extends State<TeamsGamesScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  final _scrollController = ScrollController();

  List<Player> _allPlayers = [];
  final Set<int> _selectedIds = {};
  List<List<Player>>? _teams;

  List<Game> _games = [];
  Map<int, Player> _playerMap = {};

  late AnimationController _teamsAnimController;
  late Animation<double> _teamsAnim;

  @override
  void initState() {
    super.initState();
    _loadData();
    _teamsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _teamsAnim = CurvedAnimation(
      parent: _teamsAnimController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _teamsAnimController.dispose();
    super.dispose();
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
      _showSnack('Select at least 2 players', isError: true);
      return;
    }
    setState(() => _teams = TeamBuilder.buildTeams(selected));
    _teamsAnimController.forward(from: 0);
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
    _teamsAnimController.reset();
    _showSnack('Game saved! Enter the result below.', isError: false);
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: isError ? AppColors.danger : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
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
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _teams != null ? _buildTeamsView() : _buildMainView(),
      ),
    );
  }

  // ─── Main View ────────────────────────────────────────────────────────────

  Widget _buildMainView() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Frosted top bar
        SliverAppBar(
          pinned: true,
          floating: false,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 56,
          titleSpacing: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                color: const Color(0xFF121B22).withOpacity(0.82),
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Teams & Games',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                if (_selectedIds.isNotEmpty)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedIds.length} selected',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Player selection area
        if (_allPlayers.isNotEmpty)
          SliverToBoxAdapter(child: _buildSelectionSection()),

        // Games header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(children: [
              const Text(
                'Games',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_games.length}',
                  style: const TextStyle(
                      color: AppColors.textSub, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ),

        // Games list or empty state
        _games.isEmpty
            ? SliverFillRemaining(child: _buildEmptyGames())
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildGameCard(_games[i]),
                    childCount: _games.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildSelectionSection() {
    final allSelected = _selectedIds.length == _allPlayers.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label + select all
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Row(children: [
              const Text(
                "Today's Players",
                style: TextStyle(
                  color: AppColors.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  allSelected
                      ? _selectedIds.clear()
                      : _selectedIds.addAll(_allPlayers.map((p) => p.id!));
                }),
                child: Text(
                  allSelected ? 'Deselect All' : 'Select All',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
          ),

          // Player chips
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _allPlayers.length,
              itemBuilder: (_, i) => _buildPlayerChip(_allPlayers[i]),
            ),
          ),

          const SizedBox(height: 16),

          // Make teams button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMakeTeamsButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerChip(Player player) {
    final selected = _selectedIds.contains(player.id);
    final ovr = player.overall;
    final color = ovr >= 80
        ? const Color(0xFFE8A800)
        : ovr >= 70
            ? const Color(0xFFAAB7BC)
            : const Color(0xFFCD7F32);

    return GestureDetector(
      onTap: () => setState(() {
        selected ? _selectedIds.remove(player.id) : _selectedIds.add(player.id!);
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.only(left: 12, right: 14, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: 1.2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          // OVR badge
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${player.overall}',
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            player.name,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textMain,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMakeTeamsButton() {
    final count = _selectedIds.length;
    final ready = count >= 2;
    return GestureDetector(
      onTap: ready ? _generateTeams : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: ready
              ? LinearGradient(
                  colors: [AppColors.primary, const Color(0xFF1EAD53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: ready ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: ready
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]
              : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            Icons.shuffle_rounded,
            size: 18,
            color: ready ? Colors.white : AppColors.textSub,
          ),
          const SizedBox(width: 8),
          Text(
            count == 0
                ? 'Select players to build teams'
                : count == 1
                    ? 'Select at least 2 players'
                    : 'Build Teams  ·  $count players',
            style: TextStyle(
              color: ready ? Colors.white : AppColors.textSub,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
          ),
        ]),
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
        height: 138,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.card,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(children: [
          // Football field background
          Positioned.fill(child: CustomPaint(painter: _FieldPainter())),

          // Top overlay badges
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(children: [
              if (!game.isCompleted)
                _badge(
                  label: 'Tap to enter result',
                  bgColor: const Color(0xFFFFD60A),
                  textColor: Colors.black,
                )
              else
                _badge(
                  label: '⚽  Final',
                  bgColor: AppColors.surface.withOpacity(0.9),
                  textColor: AppColors.textSub,
                ),
              const Spacer(),
              if (potg != null)
                _badge(
                  label: '⭐  ${potg.name}',
                  bgColor: const Color(0xFFE8C96D).withOpacity(0.95),
                  textColor: const Color(0xFF3A2A00),
                ),
            ]),
          ),

          // Bottom info bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0d1f18).withOpacity(0.88),
                    border: const Border(
                      top: BorderSide(color: Colors.white10, width: 0.5),
                    ),
                  ),
                  child: Row(children: [
                    // Score or team names
                    if (game.isCompleted) ...[
                      _scoreChip('Team 1', game.team1Score ?? 0,
                          winner: (game.team1Score ?? 0) > (game.team2Score ?? 0)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('vs',
                            style: TextStyle(
                                color: AppColors.textSub.withOpacity(0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      _scoreChip('Team 2', game.team2Score ?? 0,
                          winner: (game.team2Score ?? 0) > (game.team1Score ?? 0)),
                    ] else ...[
                      Expanded(
                        child: Text(
                          _gameTitle(team1, team2),
                          style: const TextStyle(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(timeStr,
                          style: const TextStyle(
                              color: AppColors.textSub, fontSize: 11, fontWeight: FontWeight.w500)),
                      Text(dateStr,
                          style: TextStyle(
                              color: AppColors.textSub.withOpacity(0.6),
                              fontSize: 10)),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _badge({required String label, required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _scoreChip(String label, int score, {required bool winner}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(label,
          style: const TextStyle(color: AppColors.textSub, fontSize: 9, fontWeight: FontWeight.w600)),
      const SizedBox(height: 1),
      Text(
        '$score',
        style: TextStyle(
          color: winner ? AppColors.primary : AppColors.textMain,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    ]);
  }

  String _gameTitle(List<Player> t1, List<Player> t2) {
    if (t1.isEmpty && t2.isEmpty) return 'Game';
    final n1 = t1.isNotEmpty ? t1.first.name.split(' ').first : 'Team 1';
    final n2 = t2.isNotEmpty ? t2.first.name.split(' ').first : 'Team 2';
    return '$n1\'s team  vs  $n2\'s team';
  }

  Widget _buildEmptyGames() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.08),
          ),
          child: const Icon(Icons.sports_soccer_rounded, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        const Text('No games yet',
            style: TextStyle(
                color: AppColors.textMain,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Build teams and kick off your first game',
            style: TextStyle(color: AppColors.textSub, fontSize: 13)),
      ]),
    );
  }

  // ─── Teams View ────────────────────────────────────────────────────────────

  Widget _buildTeamsView() {
    final team1 = _teams![0];
    final team2 = _teams![1];
    final avg1 = TeamBuilder.teamAverage(team1);
    final avg2 = TeamBuilder.teamAverage(team2);

    return FadeTransition(
      opacity: _teamsAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(_teamsAnim),
        child: Column(children: [
          // Header bar
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                color: const Color(0xFF121B22).withOpacity(0.82),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      _teams = null;
                      _teamsAnimController.reset();
                    }),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: AppColors.surface, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textMain, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Teams Ready',
                        style: TextStyle(
                            color: AppColors.textMain,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3)),
                    Text('${team1.length + team2.length} players',
                        style: const TextStyle(
                            color: AppColors.textSub, fontSize: 12)),
                  ]),
                  const Spacer(),
                  GestureDetector(
                    onTap: _generateTeams,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: const [
                        Icon(Icons.shuffle_rounded, color: AppColors.textSub, size: 14),
                        SizedBox(width: 5),
                        Text('Reshuffle',
                            style: TextStyle(
                                color: AppColors.textSub,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(children: [
                // Balance bar
                _buildBalanceBar(avg1, avg2),
                const SizedBox(height: 20),
                // Team columns
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _buildTeamCol(
                              'Team 1', team1, avg1, AppColors.primary,
                              isLeft: true)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _buildTeamCol(
                              'Team 2', team2, avg2, const Color(0xFFFF453A),
                              isLeft: false)),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ]),
            ),
          ),

          // GAME! button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: GestureDetector(
              onTap: _saveGame,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1EAD53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('⚽', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 10),
                    Text('START GAME',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildBalanceBar(int avg1, int avg2) {
    final total = avg1 + avg2;
    final ratio = total == 0 ? 0.5 : avg1 / total;
    final diff = (avg1 - avg2).abs();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(children: [
        Row(children: [
          _avgBadge('T1', avg1, AppColors.primary),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: diff <= 2
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              diff == 0 ? '⚖️  Balanced' : '±$diff OVR',
              style: TextStyle(
                color: diff <= 2 ? AppColors.primary : AppColors.textSub,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          _avgBadge('T2', avg2, const Color(0xFFFF453A)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFF453A).withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: ratio,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1EAD53)]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _avgBadge(String label, int avg, Color color) {
    return Row(children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSub, fontSize: 9, fontWeight: FontWeight.w700)),
        Text('$avg OVR',
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w900)),
      ]),
    ]);
  }

  Widget _buildTeamCol(
      String title, List<Player> team, int avg, Color color,
      {required bool isLeft}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Team header
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 14)),
          const Spacer(),
          Text('AVG $avg',
              style: const TextStyle(
                  color: AppColors.textSub, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
      const SizedBox(height: 8),
      // Players
      ...team.asMap().entries.map((e) {
        final i = e.key;
        final p = e.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 280 + i * 60),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
                offset: Offset(0, 12 * (1 - v)), child: child),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(children: [
              Expanded(
                child: Text(p.name,
                    style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _ovrColor(p.overall).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${p.overall}',
                  style: TextStyle(
                      color: _ovrColor(p.overall),
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ]),
          ),
        );
      }),
    ]);
  }

  Color _ovrColor(int ovr) {
    if (ovr >= 80) return const Color(0xFFE8A800);
    if (ovr >= 70) return const Color(0xFFAAB7BC);
    return const Color(0xFFCD7F32);
  }
}

// ─── Field Painter ────────────────────────────────────────────────────────────

class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Field gradient
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1a4a2a), Color(0xFF0d2a16)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;

    // Subtle stripe bands
    paint.color = Colors.white.withOpacity(0.025);
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(
            Rect.fromLTWH(i * size.width / 8, 0, size.width / 8, size.height),
            paint);
      }
    }

    // Field lines
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;
    paint.color = Colors.white.withOpacity(0.18);

    // Outer border
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
            const Radius.circular(2)),
        paint);

    // Center line
    canvas.drawLine(
        Offset(size.width / 2, 6), Offset(size.width / 2, size.height - 6), paint);

    // Center circle
    paint.color = Colors.white.withOpacity(0.14);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 22, paint);

    // Center dot
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2.5, paint);
    paint.style = PaintingStyle.stroke;

    // Left penalty box
    paint.color = Colors.white.withOpacity(0.15);
    canvas.drawRect(
        Rect.fromLTWH(6, size.height * 0.22, size.width * 0.2, size.height * 0.56),
        paint);

    // Right penalty box
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.8, size.height * 0.22,
            size.width * 0.2 - 6, size.height * 0.56),
        paint);
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
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
        ),

        const Text('Enter Result',
            style: TextStyle(
                color: AppColors.textMain,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3)),
        const SizedBox(height: 28),

        // Score row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _scoreBox('Team 1', _score1, (v) => setState(() => _score1 = v),
                  AppColors.primary),
              Column(children: [
                Text(
                  '$_score1 — $_score2',
                  style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _score1 == _score2
                      ? 'Draw'
                      : _score1 > _score2
                          ? 'Team 1 leads'
                          : 'Team 2 leads',
                  style: const TextStyle(color: AppColors.textSub, fontSize: 10),
                ),
              ]),
              _scoreBox('Team 2', _score2, (v) => setState(() => _score2 = v),
                  const Color(0xFFFF453A)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // POTG
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('⭐  Player of the Game',
                style: TextStyle(
                    color: AppColors.textSub,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          DropdownButtonFormField<int?>(
            value: _potgId,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textMain),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider, width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider, width: 0.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            items: [
              const DropdownMenuItem(
                  value: null,
                  child: Text('— None —',
                      style: TextStyle(color: AppColors.textSub))),
              ...all.map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name,
                      style: const TextStyle(color: AppColors.textMain)))),
            ],
            onChanged: (v) => setState(() => _potgId = v),
          ),
        ]),

        const SizedBox(height: 24),

        // Save button
        GestureDetector(
          onTap: _save,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1EAD53)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text('Save Result',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ),
        ),
      ]),
    );
  }

  Widget _scoreBox(
      String label, int value, void Function(int) onChange, Color color) {
    return Column(children: [
      Text(label,
          style: const TextStyle(
              color: AppColors.textSub, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Row(children: [
        _stepBtn(
          icon: Icons.remove_rounded,
          onTap: value > 0 ? () => onChange(value - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('$value',
              style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1)),
        ),
        _stepBtn(
          icon: Icons.add_rounded,
          onTap: () => onChange(value + 1),
        ),
      ]),
    ]);
  }

  Widget _stepBtn({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.3 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.textMain, size: 16),
        ),
      ),
    );
  }
}