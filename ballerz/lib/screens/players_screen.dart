import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/player.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _T {
  static const bg      = Color.fromARGB(255, 0, 0, 0);
  static const surface = Color(0xFF1F2C34);
  static const card    = Color(0xFF182229);
  static const primary = Color(0xFF25D366);
  static const textMain= Color(0xFFE9EDEF);
  static const textSub = Color(0xFF8696A0);
  static const divider = Color(0xFF2A3942);
  static const danger  = Color(0xFFFF3B30);
}

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});
  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _db = DatabaseService();
  List<Player> _players  = [];
  List<Player> _filtered = [];
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _sortBy     = 'name';
  String _filterType = 'all';
  bool   _selectionMode  = false;
  bool   _showTitleInBar = false;     // shows "Squad" in toolbar once header scrolls away
  final Set<int> _selectedIds = {};
  int? _lastPotmId;

  // total height of the collapsing header+search section
  static const double _collapseThreshold =
      _HeaderSearchDelegate._headerH + _HeaderSearchDelegate._searchH;

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
    if (past != _showTitleInBar) {
      setState(() => _showTitleInBar = past);
    }
  }

  Future<void> _loadPlayers() async {
    final players = await _db.getPlayers();
    final games   = await _db.getGames();
    final lastPotm = games.where((g) => g.isCompleted && g.playerOfGameId != null).toList();
    setState(() {
      _players    = players;
      _lastPotmId = lastPotm.isNotEmpty ? lastPotm.first.playerOfGameId : null;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();
    var list = _players.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.position.toLowerCase().contains(q)).toList();
    switch (_filterType) {
      case 'totw':   list = list.where((p) => p.id == _lastPotmId).toList(); break;
      case 'gold':   list = list.where((p) => p.overall >= 80).toList(); break;
      case 'silver': list = list.where((p) => p.overall >= 70 && p.overall < 80).toList(); break;
      case 'bronze': list = list.where((p) => p.overall < 70).toList(); break;
    }
    if (_sortBy == 'overall') {
      list.sort((a, b) => b.overall.compareTo(a.overall));
    } else {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    setState(() => _filtered = list);
  }

  int get _totwCount   => _players.where((p) => p.id == _lastPotmId).length;
  int get _goldCount   => _players.where((p) => p.overall >= 80).length;
  int get _silverCount => _players.where((p) => p.overall >= 70 && p.overall < 80).length;
  int get _bronzeCount => _players.where((p) => p.overall < 70).length;

  void _openPlayerDialog({Player? player}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerBottomSheet(
        player: player,
        onSave: (p) async {
          if (p.id == null) { await _db.insertPlayer(p); }
          else              { await _db.updatePlayer(p); }
          _loadPlayers();
        },
      ),
    );
  }

  void _showPlayerOptions(Player player) {
    final isTotw = player.id == _lastPotmId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(color: _T.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _posColor(player.position).withOpacity(0.18),
                        image: player.photoPath != null
                            ? DecorationImage(image: FileImage(File(player.photoPath!)), fit: BoxFit.cover)
                            : null,
                      ),
                      child: player.photoPath == null
                          ? Center(child: Text(player.name[0].toUpperCase(),
                              style: TextStyle(color: _posColor(player.position), fontWeight: FontWeight.bold, fontSize: 16)))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(player.name, style: const TextStyle(color: _T.textMain, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${player.position}  ·  OVR ${player.overall}',
                          style: const TextStyle(color: _T.textSub, fontSize: 12)),
                    ]),
                    const Spacer(),
                    if (isTotw)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE8C96D), width: 1)),
                        child: const Text('TOTW', style: TextStyle(color: Color(0xFFE8C96D), fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                  ]),
                ),
                const Divider(height: 0, thickness: 0.5, color: _T.divider),
                _optionTile(icon: Icons.edit_rounded, iconColor: _T.primary, label: 'Edit Player',
                    onTap: () { Navigator.pop(context); _openPlayerDialog(player: player); }),
                const Divider(height: 0, thickness: 0.5, color: _T.divider, indent: 56),
                _optionTile(icon: Icons.style_rounded, iconColor: const Color(0xFFE8A800), label: 'View FIFA Card',
                    onTap: () { Navigator.pop(context); _showFifaCard(player, isTotw: isTotw); }),
                const Divider(height: 0, thickness: 0.5, color: _T.divider, indent: 56),
                _optionTile(icon: Icons.delete_outline_rounded, iconColor: _T.danger, label: 'Remove Player',
                    textColor: _T.danger, onTap: () { Navigator.pop(context); _confirmDelete(player); }),
              ]),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: _T.surface, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('Cancel',
                    style: TextStyle(color: _T.textMain, fontWeight: FontWeight.w600, fontSize: 16))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon, required Color iconColor,
    required String label, required VoidCallback onTap,
    Color textColor = _T.textMain,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, color: _T.textSub.withOpacity(0.5), size: 20),
        ]),
      ),
    );
  }

  void _showFifaCard(Player player, {required bool isTotw}) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      pageBuilder: (_, __, ___) => FifaCardScreen(player: player, isTotw: isTotw),
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
        backgroundColor: _T.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Player',
            style: TextStyle(color: _T.textMain, fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text('Remove ${player.name} from your squad?',
            style: const TextStyle(color: _T.textSub, fontSize: 15)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: _T.textSub, fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _T.danger, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await _db.deletePlayer(player.id!);
              if (mounted) Navigator.pop(context);
              _loadPlayers();
            },
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
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
        backgroundColor: _T.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Players',
            style: TextStyle(color: _T.textMain, fontWeight: FontWeight.bold)),
        content: Text('Remove $count player${count > 1 ? 's' : ''}?',
            style: const TextStyle(color: _T.textSub)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: _T.textSub, fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _T.danger, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      for (final id in _selectedIds) { await _db.deletePlayer(id); }
      setState(() { _selectionMode = false; _selectedIds.clear(); });
      _loadPlayers();
    }
  }

  Color _ovrColor(int ovr) {
    if (ovr >= 85) return const Color(0xFF25D366);
    if (ovr >= 75) return const Color(0xFF128C7E);
    if (ovr >= 65) return const Color(0xFF667781);
    return const Color(0xFFAAB7BC);
  }

  Color _posColor(String pos) {
    switch (pos) {
      case 'GK':  return const Color(0xFFF59E0B);
      case 'CB': case 'LB': case 'RB': return const Color(0xFF3B82F6);
      case 'CDM': case 'CM': return const Color(0xFF8B5CF6);
      case 'CAM': case 'LW': case 'RW': return const Color(0xFFEC4899);
      case 'ST':  return const Color(0xFFEF4444);
      default:    return _T.textSub;
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── 1. Pinned toolbar — frosted glass + "Squad" when collapsed ──
            SliverAppBar(
              pinned: true,
              floating: false,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 56,
              titleSpacing: 0,
              // Blur + dark tint fills the entire toolbar area
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    color: const Color(0xFF121B22).withOpacity(0.82),
                  ),
                ),
              ),
              title: _selectionMode
                  // ── selection mode row ──────────────────────────────────
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Text('${_selectedIds.length} selected',
                            style: const TextStyle(color: _T.primary, fontSize: 16, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (_selectedIds.isNotEmpty) ...[
                          _iconButton(icon: Icons.delete_outline_rounded, color: _T.danger,
                              bg: _T.danger.withOpacity(0.12), onTap: _deleteSelected),
                          const SizedBox(width: 8),
                        ],
                        TextButton(
                          onPressed: () => setState(() { _selectionMode = false; _selectedIds.clear(); }),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              backgroundColor: _T.surface),
                          child: const Text('Done',
                              style: TextStyle(color: _T.primary, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    )
                  // ── normal mode row ─────────────────────────────────────
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left: checklist
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _iconButton(
                              icon: Icons.checklist_rounded, color: _T.textSub, bg: _T.surface,
                              onTap: () => setState(() { _selectionMode = true; _selectedIds.clear(); }),
                            ),
                          ),
                          // Center: "Squad" — fades in only after header collapses
                          AnimatedOpacity(
                            opacity: _showTitleInBar ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Text('Squad',
                                style: TextStyle(color: _T.textMain, fontSize: 17,
                                    fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                          ),
                          // Right: add player
                          Align(
                            alignment: Alignment.centerRight,
                            child: _iconButton(
                              icon: Icons.person_add_rounded, color: _T.primary,
                              bg: _T.primary.withOpacity(0.12),
                              onTap: () => _openPlayerDialog(),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // ── 2. Collapsing header + search (with sort toggle) ───────────
            SliverPersistentHeader(
              floating: false,
              delegate: _HeaderSearchDelegate(
                playerCount: _players.length,
                searchController: _searchController,
                sortBy: _sortBy,
                onSortChanged: (s) {
                  setState(() => _sortBy = s);
                  _applyFilter();
                },
              ),
            ),

            // ── 3. Horizontal filter chips (no icons) ─────────────────────
            SliverToBoxAdapter(child: _buildFilterBar()),

            // ── 4. List or empty state ────────────────────────────────────
            _filtered.isEmpty
                ? SliverFillRemaining(child: _buildEmpty())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Column(children: [
                        _buildRow(_filtered[i]),
                        if (i < _filtered.length - 1)
                          const Divider(height: 0, indent: 80, thickness: 0.5, color: _T.divider),
                      ]),
                      childCount: _filtered.length,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon, required Color color,
    required Color bg, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ── Filter chips bar — no icons, text only ─────────────────────────────────
  Widget _buildFilterBar() {
    final chips = [
      _ChipData(id: 'all',    label: 'All ${_players.length}',    color: _T.primary),
      if (_totwCount > 0)
        _ChipData(id: 'totw',   label: 'TOTW $_totwCount',          color: const Color(0xFFE8C96D)),
      if (_goldCount > 0)
        _ChipData(id: 'gold',   label: 'Gold $_goldCount',          color: const Color(0xFFE8A800)),
      if (_silverCount > 0)
        _ChipData(id: 'silver', label: 'Silver $_silverCount',      color: const Color(0xFFAAB7BC)),
      if (_bronzeCount > 0)
        _ChipData(id: 'bronze', label: 'Bronze $_bronzeCount',      color: const Color(0xFFCD7F32)),
    ];

    return Container(
      color: _T.bg,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: chips.map((c) => _buildChip(
            label: c.label,
            color: c.color,
            selected: _filterType == c.id,
            onTap: () { setState(() => _filterType = c.id); _applyFilter(); },
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label, required Color color,
    required bool selected, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : _T.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : _T.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : _T.textSub,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(Player player) {
    final isSelected = _selectedIds.contains(player.id);
    final ovrColor   = _ovrColor(player.overall);
    final posColor   = _posColor(player.position);
    final isTotw     = player.id == _lastPotmId;

    final stats = [
      ('PAC', player.pace), ('SHO', player.shooting), ('PAS', player.passing),
      ('DRI', player.dribbling), ('DEF', player.defending), ('PHY', player.physical),
    ];

    return InkWell(
      onTap: () {
        if (_selectionMode) {
          setState(() {
            isSelected ? _selectedIds.remove(player.id) : _selectedIds.add(player.id!);
          });
        } else {
          _openPlayerDialog(player: player);
        }
      },
      onLongPress: () { if (!_selectionMode) _showPlayerOptions(player); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isSelected ? _T.primary.withOpacity(0.09) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // selection circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _selectionMode ? 28 : 0,
              margin: EdgeInsets.only(right: _selectionMode ? 10 : 0),
              child: _selectionMode
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? _T.primary : Colors.transparent,
                        border: Border.all(color: isSelected ? _T.primary : _T.textSub, width: 1),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    )
                  : const SizedBox.shrink(),
            ),

            // avatar
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTotw ? Colors.black : posColor.withOpacity(0.18),
                  border: isTotw ? Border.all(color: const Color(0xFFE8C96D), width: 2) : null,
                  image: player.photoPath != null
                      ? DecorationImage(image: FileImage(File(player.photoPath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: player.photoPath == null
                    ? Center(child: Text(player.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                            color: isTotw ? const Color(0xFFE8C96D) : posColor,
                            fontWeight: FontWeight.bold, fontSize: 20)))
                    : null,
              ),
              Positioned(
                bottom: -2, right: -2,
                child: isTotw
                    ? Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE8C96D), width: 1.5)),
                        child: const Icon(Icons.star_rounded, color: Color(0xFFE8C96D), size: 10))
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: posColor, borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _T.card, width: 1.5)),
                        child: Text(player.position, style: const TextStyle(
                            color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3))),
              ),
            ]),
            const SizedBox(width: 14),

            // name + stats
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(player.name,
                      style: const TextStyle(color: _T.textMain, fontWeight: FontWeight.w600, fontSize: 15),
                      overflow: TextOverflow.ellipsis)),
                  if (isTotw) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE8C96D), width: 1)),
                      child: const Text('TOTW', style: TextStyle(
                          color: Color(0xFFE8C96D), fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
                const SizedBox(height: 7),
                Row(children: stats.map((s) => Expanded(child: _statCell(s.$1, s.$2))).toList()),
              ]),
            ),
            const SizedBox(width: 10),

            // OVR badge
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: isTotw ? Colors.black : ovrColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: isTotw ? Border.all(color: const Color(0xFFE8C96D), width: 1.5) : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${player.overall}', style: TextStyle(
                    color: isTotw ? const Color(0xFFE8C96D) : ovrColor,
                    fontWeight: FontWeight.w900, fontSize: 16)),
                Text('OVR', style: TextStyle(
                    color: (isTotw ? const Color(0xFFE8C96D) : ovrColor).withOpacity(0.7),
                    fontSize: 6, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String label, int value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          color: _T.textSub, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
      const SizedBox(height: 1),
      Text('$value', style: const TextStyle(
          color: _T.textMain, fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _T.primary.withOpacity(0.1)),
          child: const Icon(Icons.group_add_rounded, size: 48, color: _T.primary),
        ),
        const SizedBox(height: 24),
        const Text('No players yet',
            style: TextStyle(color: _T.textMain, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Tap the + button to add your first player',
            style: TextStyle(color: _T.textSub, fontSize: 14)),
      ]),
    );
  }
}

// ── chip data model ────────────────────────────────────────────────────────────
class _ChipData {
  final String id, label;
  final Color color;
  const _ChipData({required this.id, required this.label, required this.color});
}

// ─── Collapsing header + search + sort delegate ───────────────────────────────
//
// Collapse order:
//   Phase 1 (shrinkOffset 0 → _searchH)    — search bar collapses first
//   Phase 2 (shrinkOffset _searchH → max)  — "Squad" header collapses second
//
class _HeaderSearchDelegate extends SliverPersistentHeaderDelegate {
  final int playerCount;
  final TextEditingController searchController;
  final String sortBy;
  final ValueChanged<String> onSortChanged;

  static const double _headerH = 78.0;
  static const double _searchH = 45.0;

  const _HeaderSearchDelegate({
    required this.playerCount,
    required this.searchController,
    required this.sortBy,
    required this.onSortChanged,
  });

  @override double get maxExtent => _headerH + _searchH;
  @override double get minExtent => 0.0;

  @override
  bool shouldRebuild(_HeaderSearchDelegate old) =>
      playerCount != old.playerCount ||
      searchController != old.searchController ||
      sortBy != old.sortBy;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final currentH = (maxExtent - shrinkOffset).clamp(0.0, maxExtent);
    // Phase 1: search collapses
    final searchH = (currentH - _headerH).clamp(0.0, _searchH);
    // Phase 2: header collapses
    final headerH = currentH.clamp(0.0, _headerH);
    // fade out search text/icon before the bar finishes collapsing
    final searchOpacity = ((searchH / _searchH - 0.4) / 0.6).clamp(0.0, 1.0);

    return SizedBox(
      height: currentH,
      child: Container(
        color: const Color.fromARGB(255, 0, 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── "Squad" title — collapses second ──────────────────────────
            ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: headerH / _headerH,
                child: const SizedBox(
                  height: _headerH,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Squad',
                          style: TextStyle(
                            color: Color(0xFFE9EDEF),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Search row + sort toggle — collapses first ─────────────────
            ClipRect(
              child: SizedBox(
                height: searchH,
                child: Opacity(
                  opacity: searchOpacity,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                    child: Row(children: [
                      // search field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A3942),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: TextField(
                            controller: searchController,
                            style: const TextStyle(color: Color(0xFFE9EDEF), fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Search…',
                              hintStyle: TextStyle(color: Color(0xFF8696A0), fontSize: 14),
                              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF8696A0), size: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // sort toggle — tapping cycles name ↔ overall
                      GestureDetector(
                        onTap: () => onSortChanged(sortBy == 'name' ? 'overall' : 'name'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A3942),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              sortBy == 'name'
                                  ? Icons.sort_by_alpha_rounded
                                  : Icons.filter_list_rounded,
                              color: const Color(0xFF8696A0),
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              sortBy == 'name' ? 'A–Z' : 'OVR',
                              style: const TextStyle(
                                color: Color(0xFF8696A0),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FIFA Card Screen ─────────────────────────────────────────────────────────
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
                _buildContent(context),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
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
                fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5, height: 1)),
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
                    child: Image.file(File(player.photoPath!), width: 200, height: 260, fit: BoxFit.contain),
                  ))
              : Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: _textColor.withOpacity(0.15),
                      border: Border.all(color: _textColor.withOpacity(0.3), width: 2)),
                  child: Center(child: Text(player.name[0].toUpperCase(),
                      style: TextStyle(color: _textColor, fontSize: 48, fontWeight: FontWeight.w900)))),
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
            _cardStat('PAC', player.pace), _cardStat('SHO', player.shooting),
            _cardStat('PAS', player.passing), _cardStat('DRI', player.dribbling),
            _cardStat('DEF', player.defending), _cardStat('PHY', player.physical),
          ]),
        ),
      ]),
    );
  }

  Widget _cardStat(String label, int value) {
    return Column(children: [
      Text(label, style: TextStyle(fontFamily: 'EACondMedium', color: _subTextColor,
          fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
      Text('$value', style: TextStyle(fontFamily: 'EACondMedium', color: _textColor,
          fontSize: 21, fontWeight: FontWeight.w700)),
    ]);
  }
}

// ─── Player Bottom Sheet ──────────────────────────────────────────────────────
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

  static const _positions = ['GK','CB','LB','RB','CDM','CM','CAM','LW','RW','ST'];

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

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    widget.onSave(Player(
      id: widget.player?.id,
      name: _nameController.text.trim(),
      position: _position,
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
      backgroundColor: _T.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: _T.divider, borderRadius: BorderRadius.circular(2))),
          _photoOption(icon: Icons.camera_alt_rounded, label: 'Take a photo', onTap: () async {
            Navigator.pop(context);
            final xfile = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
            if (xfile != null) setState(() => _photoPath = xfile.path);
          }),
          _photoOption(icon: Icons.photo_library_rounded, label: 'Choose from gallery', onTap: () async {
            Navigator.pop(context);
            final xfile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
            if (xfile != null) setState(() => _photoPath = xfile.path);
          }),
          if (_photoPath != null)
            _photoOption(icon: Icons.delete_rounded, label: 'Remove photo', color: _T.danger, onTap: () {
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
    required VoidCallback onTap, Color color = _T.textMain,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: color == _T.textMain ? _T.primary.withOpacity(0.12) : _T.danger.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color == _T.textMain ? _T.primary : _T.danger, size: 20),
      ),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 15)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final overall = (_stats.values.fold(0.0, (a, b) => a + b) / 6).round();
    return Container(
      decoration: const BoxDecoration(
          color: _T.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: _T.divider, borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.player == null ? 'New Player' : 'Edit Player',
                  style: const TextStyle(color: _T.textMain, fontSize: 22,
                      fontWeight: FontWeight.bold, letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Text(widget.player == null ? 'Fill in the details below' : 'Update player info',
                  style: const TextStyle(color: _T.textSub, fontSize: 13)),
            ])),
            GestureDetector(
              onTap: _pickPhoto,
              child: Stack(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: _T.primary.withOpacity(0.12),
                    border: Border.all(color: _T.primary.withOpacity(0.3), width: 2),
                    image: _photoPath != null
                        ? DecorationImage(image: FileImage(File(_photoPath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _photoPath == null
                      ? const Icon(Icons.person_rounded, color: _T.primary, size: 30)
                      : null,
                ),
                Positioned(bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: _T.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                  )),
              ]),
            ),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(flex: 3, child: _field(child: TextField(
              controller: _nameController,
              style: const TextStyle(color: _T.textMain, fontWeight: FontWeight.w500, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Player name', hintStyle: TextStyle(color: _T.textSub),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.person_outline_rounded, color: _T.textSub, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ))),
            const SizedBox(width: 10),
            Expanded(flex: 1, child: _field(child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _position, dropdownColor: _T.surface,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _T.textSub, size: 20),
                style: const TextStyle(color: _T.textMain, fontWeight: FontWeight.bold, fontSize: 15),
                isExpanded: true, padding: const EdgeInsets.symmetric(horizontal: 14),
                items: _positions.map((p) => DropdownMenuItem(
                    value: p, child: Text(p, style: const TextStyle(color: _T.textMain)))).toList(),
                onChanged: (v) => setState(() => _position = v!),
              ),
            ))),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            const Text('Attributes', style: TextStyle(
                color: _T.textMain, fontSize: 17, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: _T.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Text('OVR  $overall', style: const TextStyle(
                  color: _T.primary, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ]),
          const SizedBox(height: 12),
          ..._stats.entries.map((e) => _buildSlider(e.key, e.value)),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: _T.divider, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Cancel', style: TextStyle(
                  color: _T.textSub, fontWeight: FontWeight.w600, fontSize: 15)),
            )),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.primary, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save Player', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _field({required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: _T.bg, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }

  Widget _buildSlider(String label, double value) {
    final pct   = ((value - 1) / 98);
    final color = Color.lerp(const Color(0xFF3D5A6B), _T.primary, pct)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(width: 38, child: Text(label, style: const TextStyle(
            color: _T.textSub, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3))),
        Expanded(child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color, inactiveTrackColor: _T.divider, thumbColor: color,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            overlayColor: _T.primary.withOpacity(0.12),
          ),
          child: Slider(value: value, min: 1, max: 99, onChanged: (v) => setState(() => _stats[label] = v)),
        )),
        SizedBox(width: 32, child: Text('${value.round()}',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
            textAlign: TextAlign.right)),
      ]),
    );
  }
}