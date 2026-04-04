import 'dart:ui';
import 'package:flutter/material.dart' hide FilterChip;
import '../models/player.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/players/player_row.dart';
import '../widgets/players/player_options_sheet.dart';
import '../widgets/players/players_filter_bar.dart';
import '../widgets/players/players_header_delegate.dart';
import '../widgets/players/player_bottom_sheet.dart';
import '../widgets/players/fifa_card_screen.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});
  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _db = DatabaseService();
  List<Player> _players = [];
  List<Player> _filtered = [];
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _sortBy = 'name';
  String _filterType = 'all';
  bool _selectionMode = false;
  bool _showTitleInBar = false;
  final Set<int> _selectedIds = {};
  int? _lastPotmId;

  static const double _collapseThreshold =
      HeaderSearchDelegate.headerH + HeaderSearchDelegate.searchH;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _searchController.addListener(_applyFilter);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final past = _scrollController.offset > _collapseThreshold;
    if (past != _showTitleInBar) setState(() => _showTitleInBar = past);
  }

  Future<void> _loadPlayers() async {
    final players = await _db.getPlayers();
    final games = await _db.getGames();
    final lastPotm =
        games.where((g) => g.isCompleted && g.playerOfGameId != null).toList();
    setState(() {
      _players = players;
      _lastPotmId = lastPotm.isNotEmpty ? lastPotm.first.playerOfGameId : null;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();
    var list = _players
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.position.toLowerCase().contains(q))
        .toList();
    switch (_filterType) {
      case 'totw':
        list = list.where((p) => p.id == _lastPotmId).toList();
        break;
      case 'gold':
        list = list.where((p) => p.overall >= 80).toList();
        break;
      case 'silver':
        list = list.where((p) => p.overall >= 70 && p.overall < 80).toList();
        break;
      case 'bronze':
        list = list.where((p) => p.overall < 70).toList();
        break;
    }
    if (_sortBy == 'overall') {
      list.sort((a, b) => b.overall.compareTo(a.overall));
    } else {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    setState(() => _filtered = list);
  }

  int get _totwCount => _players.where((p) => p.id == _lastPotmId).length;
  int get _goldCount => _players.where((p) => p.overall >= 80).length;
  int get _silverCount =>
      _players.where((p) => p.overall >= 70 && p.overall < 80).length;
  int get _bronzeCount => _players.where((p) => p.overall < 70).length;

  void _openPlayerDialog({Player? player}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerBottomSheet(
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

  void _openPlayerOptions(Player player) {
    final isTotw = player.id == _lastPotmId;
    showPlayerOptionsSheet(
      context: context,
      player: player,
      isTotw: isTotw,
      onEdit: () {
        Navigator.pop(context);
        _openPlayerDialog(player: player);
      },
      onViewCard: () {
        Navigator.pop(context);
        _showFifaCard(player, isTotw: isTotw);
      },
      onDelete: () {
        Navigator.pop(context);
        _confirmDelete(player);
      },
    );
  }

  void _showFifaCard(Player player, {required bool isTotw}) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      pageBuilder: (_, __, ___) =>
          FifaCardScreen(player: player, isTotw: isTotw),
      transitionsBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
    ));
  }

  void _confirmDelete(Player player) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Player',
            style: TextStyle(
                color: AppColors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        content: Text('Remove ${player.name} from your squad?',
            style: const TextStyle(color: AppColors.textSub, fontSize: 15)),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textSub, fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await _db.deletePlayer(player.id!);
              if (mounted) Navigator.pop(context);
              _loadPlayers();
            },
            child: const Text('Remove',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Players',
            style: TextStyle(
                color: AppColors.textMain, fontWeight: FontWeight.bold)),
        content: Text('Remove $count player${count > 1 ? 's' : ''}?',
            style: const TextStyle(color: AppColors.textSub)),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.textSub, fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final id in _selectedIds) {
        await _db.deletePlayer(id);
      }
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
      _loadPlayers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterChips = [
      FilterChip(
          id: 'all', label: 'All ${_players.length}', color: AppColors.primary),
      if (_totwCount > 0)
        FilterChip(
            id: 'totw',
            label: 'TOTW $_totwCount',
            color: const Color(0xFFE8C96D)),
      if (_goldCount > 0)
        FilterChip(
            id: 'gold',
            label: 'Gold $_goldCount',
            color: const Color(0xFFE8A800)),
      if (_silverCount > 0)
        FilterChip(
            id: 'silver',
            label: 'Silver $_silverCount',
            color: const Color(0xFFAAB7BC)),
      if (_bronzeCount > 0)
        FilterChip(
            id: 'bronze',
            label: 'Bronze $_bronzeCount',
            color: const Color(0xFFCD7F32)),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Pinned frosted toolbar
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
                      color: const Color(0xFF121B22).withOpacity(0.82)),
                ),
              ),
              title: _selectionMode ? _selectionBar() : _normalBar(),
            ),

            // 2. Collapsing header + search + sort
            SliverPersistentHeader(
              floating: false,
              delegate: HeaderSearchDelegate(
                playerCount: _players.length,
                searchController: _searchController,
                sortBy: _sortBy,
                onSortChanged: (s) {
                  setState(() => _sortBy = s);
                  _applyFilter();
                },
              ),
            ),

            // 3. Pinned filter chips
            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedFilterBarDelegate(
                child: PlayersFilterBar(
                  chips: filterChips,
                  selectedId: _filterType,
                  onSelected: (id) {
                    setState(() => _filterType = id);
                    _applyFilter();
                  },
                ),
              ),
            ),

            // 4. Player list / empty state
            _filtered.isEmpty
                ? SliverFillRemaining(child: _buildEmpty())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Column(children: [
                        PlayerRow(
                          player: _filtered[i],
                          isTotw: _filtered[i].id == _lastPotmId,
                          isSelected: _selectedIds.contains(_filtered[i].id),
                          selectionMode: _selectionMode,
                          onTap: () {
                            if (_selectionMode) {
                              setState(() {
                                final id = _filtered[i].id!;
                                _selectedIds.contains(id)
                                    ? _selectedIds.remove(id)
                                    : _selectedIds.add(id);
                              });
                            } else {
                              _openPlayerDialog(player: _filtered[i]);
                            }
                          },
                          onLongPress: () {
                            if (!_selectionMode)
                              _openPlayerOptions(_filtered[i]);
                          },
                        ),
                        if (i < _filtered.length - 1)
                          const Divider(
                              height: 0,
                              indent: 80,
                              thickness: 0.5,
                              color: AppColors.divider),
                      ]),
                      childCount: _filtered.length,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _normalBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(alignment: Alignment.center, children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _iconButton(
              icon: Icons.checklist_rounded,
              color: AppColors.textSub,
              bg: AppColors.surface,
              onTap: () => setState(() {
                    _selectionMode = true;
                    _selectedIds.clear();
                  })),
        ),
        AnimatedOpacity(
          opacity: _showTitleInBar ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: const Text('Squad',
              style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: _iconButton(
              icon: Icons.person_add_rounded,
              color: AppColors.primary,
              bg: AppColors.primary.withOpacity(0.12),
              onTap: () => _openPlayerDialog()),
        ),
      ]),
    );
  }

  Widget _selectionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Text('${_selectedIds.length} selected',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const Spacer(),
        if (_selectedIds.isNotEmpty) ...[
          _iconButton(
              icon: Icons.delete_outline_rounded,
              color: AppColors.danger,
              bg: AppColors.danger.withOpacity(0.12),
              onTap: _deleteSelected),
          const SizedBox(width: 8),
        ],
        TextButton(
          onPressed: () => setState(() {
            _selectionMode = false;
            _selectedIds.clear();
          }),
          style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.surface),
          child: const Text('Done',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1)),
          child: const Icon(Icons.group_add_rounded,
              size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        const Text('No players yet',
            style: TextStyle(
                color: AppColors.textMain,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Tap the + button to add your first player',
            style: TextStyle(color: AppColors.textSub, fontSize: 14)),
      ]),
    );
  }
}
