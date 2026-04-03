import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/player.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _T {
  static const bg = Color(0xFFF0F2F5);
  static const surface = Colors.white;
  static const primary = Color(0xFF25D366);
  static const textMain = Color(0xFF111B21);
  static const textSub = Color(0xFF667781);
  static const divider = Color(0xFFE9EDEF);
  static const danger = Color(0xFFFF3B30);
}

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
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};
  int? _lastPotmId; // last completed game's player of the match

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    final players = await _db.getPlayers();
    final games = await _db.getGames();
    // Most recent completed game with a POTM
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
    if (_sortBy == 'overall') {
      list.sort((a, b) => b.overall.compareTo(a.overall));
    } else {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    setState(() => _filtered = list);
  }

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

  // ── Long press options sheet ────────────────────────────────────────────────
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
            // Main actions card
            Container(
              decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Player name header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _posColor(player.position).withOpacity(0.12),
                            image: player.photoPath != null
                                ? DecorationImage(
                                    image: FileImage(File(player.photoPath!)),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: player.photoPath == null
                              ? Center(
                                  child: Text(
                                    player.name[0].toUpperCase(),
                                    style: TextStyle(
                                        color: _posColor(player.position),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player.name,
                                style: const TextStyle(
                                    color: _T.textMain,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text('${player.position}  ·  OVR ${player.overall}',
                                style: const TextStyle(
                                    color: _T.textSub, fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        if (isTotw)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFE8C96D), width: 1),
                            ),
                            child: const Text('TOTW',
                                style: TextStyle(
                                    color: Color(0xFFE8C96D),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 0, thickness: 0.5, color: _T.divider),

                  // Edit
                  _optionTile(
                    icon: Icons.edit_rounded,
                    iconColor: _T.primary,
                    label: 'Edit Player',
                    onTap: () {
                      Navigator.pop(context);
                      _openPlayerDialog(player: player);
                    },
                  ),
                  const Divider(
                      height: 0, thickness: 0.5, color: _T.divider, indent: 56),

                  // FIFA Card
                  _optionTile(
                    icon: Icons.style_rounded,
                    iconColor: const Color(0xFFE8A800),
                    label: 'View FIFA Card',
                    onTap: () {
                      Navigator.pop(context);
                      _showFifaCard(player, isTotw: isTotw);
                    },
                  ),
                  const Divider(
                      height: 0, thickness: 0.5, color: _T.divider, indent: 56),

                  // Delete
                  _optionTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: _T.danger,
                    label: 'Remove Player',
                    textColor: _T.danger,
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDelete(player);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Cancel button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _T.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('Cancel',
                      style: TextStyle(
                          color: _T.textMain,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    Color textColor = _T.textMain,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: _T.textSub.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  // ── FIFA Card viewer ────────────────────────────────────────────────────────
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
        backgroundColor: _T.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Player',
            style: TextStyle(
                color: _T.textMain, fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text('Remove ${player.name} from your squad?',
            style: const TextStyle(color: _T.textSub, fontSize: 15)),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style:
                    TextStyle(color: _T.textSub, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
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
        backgroundColor: _T.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Players',
            style: TextStyle(color: _T.textMain, fontWeight: FontWeight.bold)),
        content: Text('Remove $count player${count > 1 ? 's' : ''}?',
            style: const TextStyle(color: _T.textSub)),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style:
                    TextStyle(color: _T.textSub, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
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

  Color _ovrColor(int ovr) {
    if (ovr >= 85) return const Color(0xFF25D366);
    if (ovr >= 75) return const Color(0xFF128C7E);
    if (ovr >= 65) return const Color(0xFF667781);
    return const Color(0xFFAAB7BC);
  }

  Color _posColor(String pos) {
    switch (pos) {
      case 'GK':
        return const Color(0xFFF59E0B);
      case 'CB':
      case 'LB':
      case 'RB':
        return const Color(0xFF3B82F6);
      case 'CDM':
      case 'CM':
        return const Color(0xFF8B5CF6);
      case 'CAM':
      case 'LW':
      case 'RW':
        return const Color(0xFFEC4899);
      case 'ST':
        return const Color(0xFFEF4444);
      default:
        return _T.textSub;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            if (_filtered.isNotEmpty) _buildStatsBar(),
            Expanded(
              child: _filtered.isEmpty ? _buildEmpty() : _buildList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _openPlayerDialog(),
              backgroundColor: _T.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.person_add_rounded, size: 26),
            ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _T.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_rounded, color: _T.primary, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '${_filtered.length} player${_filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: _T.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() {
                _sortBy = _sortBy == 'name' ? 'overall' : 'name';
                _applyFilter();
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _T.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _T.divider, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'name'
                          ? Icons.sort_by_alpha_rounded
                          : Icons.filter_list_rounded,
                      color: _T.textSub,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _sortBy == 'name' ? 'Name' : 'OVR',
                      style: const TextStyle(
                          color: _T.textSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _T.textSub, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Squad',
                  style: TextStyle(
                      color: _T.textMain,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              Text('${_players.length} members',
                  style: const TextStyle(color: _T.textSub, fontSize: 13)),
            ],
          ),
          const Spacer(),
          if (_selectionMode) ...[
            Text('${_selectedIds.length} selected',
                style: const TextStyle(
                    color: _T.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            if (_selectedIds.isNotEmpty)
              _iconButton(
                icon: Icons.delete_outline_rounded,
                color: _T.danger,
                bg: _T.danger.withOpacity(0.1),
                onTap: _deleteSelected,
              ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() {
                _selectionMode = false;
                _selectedIds.clear();
              }),
              style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  backgroundColor: _T.bg),
              child: const Text('Done',
                  style: TextStyle(
                      color: _T.primary, fontWeight: FontWeight.w700)),
            ),
          ] else ...[
            _iconButton(
              icon: Icons.checklist_rounded,
              color: _T.textSub,
              bg: _T.bg,
              onTap: () => setState(() {
                _selectionMode = true;
                _selectedIds.clear();
              }),
            ),
          ],
        ],
      ),
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

  Widget _buildSearchBar() {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: _T.textMain, fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'Search name or position...',
            hintStyle: TextStyle(color: _T.textSub, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: _T.textSub, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Container(
      color: _T.surface,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const Divider(
          height: 0,
          indent: 80,
          thickness: 0.5,
          color: _T.divider,
        ),
        itemBuilder: (_, i) => _buildRow(_filtered[i]),
      ),
    );
  }

  Widget _buildRow(Player player) {
    final isSelected = _selectedIds.contains(player.id);
    final ovrColor = _ovrColor(player.overall);
    final posColor = _posColor(player.position);
    final isTotw = player.id == _lastPotmId;

    final stats = [
      ('PAC', player.pace),
      ('SHO', player.shooting),
      ('PAS', player.passing),
      ('DRI', player.dribbling),
      ('DEF', player.defending),
      ('PHY', player.physical),
    ];

    return InkWell(
      onTap: () {
        if (_selectionMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(player.id);
            } else {
              _selectedIds.add(player.id!);
            }
          });
        } else {
          _openPlayerDialog(player: player);
        }
      },
      onLongPress: () {
        if (!_selectionMode) _showPlayerOptions(player);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isSelected ? _T.primary.withOpacity(0.07) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Selection circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _selectionMode ? 28 : 0,
              margin: EdgeInsets.only(right: _selectionMode ? 10 : 0),
              child: _selectionMode
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? _T.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? _T.primary : _T.textSub,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 14)
                          : null,
                    )
                  : const SizedBox.shrink(),
            ),

            // Avatar + position badge + TOTW crown
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTotw ? Colors.black : posColor.withOpacity(0.12),
                    border: isTotw
                        ? Border.all(color: const Color(0xFFE8C96D), width: 2)
                        : null,
                    image: player.photoPath != null
                        ? DecorationImage(
                            image: FileImage(File(player.photoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: player.photoPath == null
                      ? Center(
                          child: Text(
                            player.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                                color:
                                    isTotw ? const Color(0xFFE8C96D) : posColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        )
                      : null,
                ),
                // TOTW star or position badge
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: isTotw
                      ? Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFE8C96D), width: 1.5),
                          ),
                          child: const Icon(Icons.star_rounded,
                              color: Color(0xFFE8C96D), size: 10),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: posColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            player.position,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Name + 6 stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          style: const TextStyle(
                              color: _T.textMain,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: stats
                        .map((s) => Expanded(child: _statCell(s.$1, s.$2)))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // OVR badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isTotw ? Colors.black : ovrColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: isTotw
                    ? Border.all(color: const Color(0xFFE8C96D), width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${player.overall}',
                    style: TextStyle(
                        color: isTotw ? const Color(0xFFE8C96D) : ovrColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16),
                  ),
                  Text(
                    'OVR',
                    style: TextStyle(
                        color: isTotw
                            ? const Color(0xFFE8C96D).withOpacity(0.7)
                            : ovrColor.withOpacity(0.7),
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _T.textSub,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
        const SizedBox(height: 1),
        Text('$value',
            style: const TextStyle(
                color: _T.textMain, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _T.primary.withOpacity(0.08),
            ),
            child: const Icon(Icons.group_add_rounded,
                size: 48, color: _T.primary),
          ),
          const SizedBox(height: 24),
          const Text('No players yet',
              style: TextStyle(
                  color: _T.textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tap the + button to add your first player',
              style: TextStyle(color: _T.textSub, fontSize: 14)),
        ],
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

  // Text color per card type — matching each card's aesthetic
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
            onTap: () {}, // prevent dismiss when tapping card itself
            child: SizedBox(
              width: 260,
              height: 360,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Card background image
                  Positioned.fill(
                    child: Image.asset(
                      _cardAsset,
                      fit: BoxFit.fill,
                    ),
                  ),
                  // Card content overlay
                  _buildContent(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: OVR + Position
          Padding(
            padding: isTotw
                ? const EdgeInsets.only(left: 28, top: 70)
                : const EdgeInsets.only(left: 22, top: 80),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // center OVR and position together
              children: [
                Text(
                  '${player.overall}',
                  style: TextStyle(
                    fontFamily: 'EACondMedium',
                    color: _textColor,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                Text(
                  player.position,
                  style: TextStyle(
                    fontFamily: 'EACondBold',
                    color: _textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),

          // ── Player photo
          SizedBox(
            height: 86,
            child: Center(
              child: player.photoPath != null
                  ? OverflowBox(
                      maxHeight:
                          140, // taller than the SizedBox — bleeds upward
                      alignment: Alignment.bottomCenter,
                      child: ShaderMask(
                        shaderCallback: (rect) => LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: isTotw
                              ? [0.6, 1.0]
                              : [1.0, 1.0], // fade starts at 60% down
                          colors: const [Colors.white, Colors.transparent],
                        ).createShader(rect),
                        blendMode: BlendMode.dstIn,
                        child: Image.file(
                          File(player.photoPath!),
                          width: 200,
                          height: 260,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _textColor.withOpacity(0.15),
                        border: Border.all(
                            color: _textColor.withOpacity(0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          player.name[0].toUpperCase(),
                          style: TextStyle(
                              color: _textColor,
                              fontSize: 48,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
            ),
          ),

          if (isTotw) const SizedBox(height: 20) else const SizedBox(height: 8),

          // ── Player name
          Center(
            child: Text(
              player.name.toUpperCase(),
              style: TextStyle(
                fontFamily: 'EACondBold',
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── 6 Stats row
          Padding(
            padding: isTotw
                ? const EdgeInsets.symmetric(horizontal: 24)
                : const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _cardStat('PAC', player.pace),
                _cardStat('SHO', player.shooting),
                _cardStat('PAS', player.passing),
                _cardStat('DRI', player.dribbling),
                _cardStat('DEF', player.defending),
                _cardStat('PHY', player.physical),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardStat(String label, int value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
              fontFamily: 'EACondMedium',
              color: _subTextColor,
              fontSize: 14, // bigger
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            )),
        Text('$value',
            style: TextStyle(
              fontFamily: 'EACondMedium',
              color: _textColor,
              fontSize: 21, // bigger
              fontWeight: FontWeight.w700,
            ))
      ],
    );
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

  static const _positions = [
    'GK',
    'CB',
    'LB',
    'RB',
    'CDM',
    'CM',
    'CAM',
    'LW',
    'RW',
    'ST'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.player;
    _nameController.text = p?.name ?? '';
    _position = p?.position ?? 'ST';
    _photoPath = p?.photoPath;
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
    widget.onSave(Player(
      id: widget.player?.id,
      name: _nameController.text.trim(),
      position: _position,
      pace: _stats['PAC']!.round(),
      shooting: _stats['SHO']!.round(),
      passing: _stats['PAS']!.round(),
      dribbling: _stats['DRI']!.round(),
      defending: _stats['DEF']!.round(),
      physical: _stats['PHY']!.round(),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: _T.divider, borderRadius: BorderRadius.circular(2)),
            ),
            _photoOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a photo',
              onTap: () async {
                Navigator.pop(context);
                final xfile = await ImagePicker()
                    .pickImage(source: ImageSource.camera, imageQuality: 85);
                if (xfile != null) setState(() => _photoPath = xfile.path);
              },
            ),
            _photoOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from gallery',
              onTap: () async {
                Navigator.pop(context);
                final xfile = await ImagePicker()
                    .pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (xfile != null) setState(() => _photoPath = xfile.path);
              },
            ),
            if (_photoPath != null)
              _photoOption(
                icon: Icons.delete_rounded,
                label: 'Remove photo',
                color: _T.danger,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _photoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = _T.textMain,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color == _T.textMain
              ? _T.primary.withOpacity(0.1)
              : _T.danger.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: color == _T.textMain ? _T.primary : _T.danger, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w500, fontSize: 15)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final overall = (_stats.values.fold(0.0, (a, b) => a + b) / 6).round();

    return Container(
      decoration: const BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: _T.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.player == null ? 'New Player' : 'Edit Player',
                        style: const TextStyle(
                            color: _T.textMain,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.player == null
                            ? 'Fill in the details below'
                            : 'Update player info',
                        style: const TextStyle(color: _T.textSub, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _T.primary.withOpacity(0.1),
                          border: Border.all(
                              color: _T.primary.withOpacity(0.3), width: 2),
                          image: _photoPath != null
                              ? DecorationImage(
                                  image: FileImage(File(_photoPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _photoPath == null
                            ? const Icon(Icons.person_rounded,
                                color: _T.primary, size: 30)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                              color: _T.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _field(
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(
                          color: _T.textMain,
                          fontWeight: FontWeight.w500,
                          fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Player name',
                        hintStyle: TextStyle(color: _T.textSub),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.person_outline_rounded,
                            color: _T.textSub, size: 20),
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: _field(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _position,
                        dropdownColor: _T.surface,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: _T.textSub, size: 20),
                        style: const TextStyle(
                            color: _T.textMain,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        items: _positions
                            .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p,
                                    style:
                                        const TextStyle(color: _T.textMain))))
                            .toList(),
                        onChanged: (v) => setState(() => _position = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Attributes',
                    style: TextStyle(
                        color: _T.textMain,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _T.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('OVR  $overall',
                      style: const TextStyle(
                          color: _T.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._stats.entries.map((e) => _buildSlider(e.key, e.value)),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: _T.divider, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: _T.textSub,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Player',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _buildSlider(String label, double value) {
    final pct = ((value - 1) / 98);
    final color = Color.lerp(const Color(0xFFAAB7BC), _T.primary, pct)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(label,
                style: const TextStyle(
                    color: _T.textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: _T.divider,
                thumbColor: color,
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                overlayColor: _T.primary.withOpacity(0.1),
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
            width: 32,
            child: Text(
              '${value.round()}',
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.w800),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
