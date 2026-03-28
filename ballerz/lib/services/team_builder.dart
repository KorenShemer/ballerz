import '../models/player.dart';

class TeamBuilder {
  /// Splits [players] into two teams with the most balanced total overall rating.
  /// Uses a greedy algorithm: sort by overall DESC, then always assign the next
  /// player to whichever team currently has the lower total.
  static List<List<Player>> buildTeams(List<Player> players) {
    if (players.isEmpty) return [[], []];

    final sorted = List<Player>.from(players)
      ..sort((a, b) => b.overall.compareTo(a.overall));

    final team1 = <Player>[];
    final team2 = <Player>[];
    int sum1 = 0, sum2 = 0;

    for (final player in sorted) {
      if (sum1 <= sum2) {
        team1.add(player);
        sum1 += player.overall;
      } else {
        team2.add(player);
        sum2 += player.overall;
      }
    }

    return [team1, team2];
  }

  static int teamTotal(List<Player> team) =>
      team.fold(0, (sum, p) => sum + p.overall);

  static int teamAverage(List<Player> team) =>
      team.isEmpty ? 0 : (teamTotal(team) / team.length).round();
}