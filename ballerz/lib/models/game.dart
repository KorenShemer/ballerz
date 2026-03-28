class Game {
  final int? id;
  final String team1Players; // comma-separated player IDs
  final String team2Players;
  final int? team1Score;
  final int? team2Score;
  final int? winnerTeam; // 1, 2, or 0 for draw
  final int? playerOfGameId;
  final DateTime date;
  final bool isCompleted;

  Game({
    this.id,
    required this.team1Players,
    required this.team2Players,
    this.team1Score,
    this.team2Score,
    this.winnerTeam,
    this.playerOfGameId,
    required this.date,
    this.isCompleted = false,
  });

  List<int> get team1Ids =>
      team1Players.split(',').where((s) => s.isNotEmpty).map(int.parse).toList();

  List<int> get team2Ids =>
      team2Players.split(',').where((s) => s.isNotEmpty).map(int.parse).toList();

  Map<String, dynamic> toMap() => {
        'id': id,
        'team1Players': team1Players,
        'team2Players': team2Players,
        'team1Score': team1Score,
        'team2Score': team2Score,
        'winnerTeam': winnerTeam,
        'playerOfGameId': playerOfGameId,
        'date': date.toIso8601String(),
        'isCompleted': isCompleted ? 1 : 0,
      };

  factory Game.fromMap(Map<String, dynamic> map) => Game(
        id: map['id'],
        team1Players: map['team1Players'],
        team2Players: map['team2Players'],
        team1Score: map['team1Score'],
        team2Score: map['team2Score'],
        winnerTeam: map['winnerTeam'],
        playerOfGameId: map['playerOfGameId'],
        date: DateTime.parse(map['date']),
        isCompleted: map['isCompleted'] == 1,
      );

  Game copyWith({
    int? id,
    String? team1Players,
    String? team2Players,
    int? team1Score,
    int? team2Score,
    int? winnerTeam,
    int? playerOfGameId,
    DateTime? date,
    bool? isCompleted,
  }) =>
      Game(
        id: id ?? this.id,
        team1Players: team1Players ?? this.team1Players,
        team2Players: team2Players ?? this.team2Players,
        team1Score: team1Score ?? this.team1Score,
        team2Score: team2Score ?? this.team2Score,
        winnerTeam: winnerTeam ?? this.winnerTeam,
        playerOfGameId: playerOfGameId ?? this.playerOfGameId,
        date: date ?? this.date,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}