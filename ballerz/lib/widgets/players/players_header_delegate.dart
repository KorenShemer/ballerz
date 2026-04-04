import 'package:flutter/material.dart';

// Collapse order:
//   Phase 1 (shrinkOffset 0 → searchH)   — search bar collapses first
//   Phase 2 (shrinkOffset searchH → max) — "Squad" header collapses second
class HeaderSearchDelegate extends SliverPersistentHeaderDelegate {
  final int playerCount;
  final TextEditingController searchController;
  final String sortBy;
  final ValueChanged<String> onSortChanged;

  static const double headerH = 78.0;
  static const double searchH = 45.0;

  const HeaderSearchDelegate({
    required this.playerCount,
    required this.searchController,
    required this.sortBy,
    required this.onSortChanged,
  });

  @override double get maxExtent => headerH + searchH;
  @override double get minExtent => 0.0;

  @override
  bool shouldRebuild(HeaderSearchDelegate old) =>
      playerCount != old.playerCount ||
      searchController != old.searchController ||
      sortBy != old.sortBy;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final currentH     = (maxExtent - shrinkOffset).clamp(0.0, maxExtent);
    final searchHVal   = (currentH - headerH).clamp(0.0, searchH);
    final headerHVal   = currentH.clamp(0.0, headerH);
    // Whole-row fade
    final rowOpacity   = ((searchHVal / searchH - 0.4) / 0.6).clamp(0.0, 1.0);
    // Hint + sort fade (disappear in first 20% of collapse)
    final hintOpacity  = ((searchHVal / searchH - 0.8) / 0.2).clamp(0.0, 1.0);
    final hintColor    = Color(0xFF8696A0).withOpacity(hintOpacity);
    final sortColor    = Color(0xFF8696A0).withOpacity(hintOpacity);

    return SizedBox(
      height: currentH,
      child: Container(
        color: const Color(0xFF000000),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title — collapses second ──────────────────────────────────
            ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: headerHVal / headerH,
                child: SizedBox(
                  height: headerH,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Squad', style: TextStyle(
                          color: Color(0xFFE9EDEF), fontSize: 28,
                          fontWeight: FontWeight.w800, letterSpacing: -0.5,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Search + sort row — collapses first ───────────────────────
            ClipRect(
              child: SizedBox(
                height: searchHVal,
                child: Opacity(
                  opacity: rowOpacity,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                    child: Row(children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A3942),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: TextField(
                            controller: searchController,
                            style: const TextStyle(
                                color: Color(0xFFE9EDEF), fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Search…',
                              hintStyle: TextStyle(color: hintColor, fontSize: 14),
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: hintColor, size: 18),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onSortChanged(
                            sortBy == 'name' ? 'overall' : 'name'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A3942),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              sortBy == 'name'
                                  ? Icons.sort_by_alpha_rounded
                                  : Icons.filter_list_rounded,
                              color: sortColor, size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(sortBy == 'name' ? 'A–Z' : 'OVR',
                                style: TextStyle(
                                    color: sortColor, fontSize: 12,
                                    fontWeight: FontWeight.w600)),
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