class Player {
  final int? id;
  final String name;
  final String position;
  final int pace, shooting, passing, dribbling, defending, physical;
  final String? photoPath;

  Player({
    this.id,
    required this.name,
    required this.position,
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defending,
    required this.physical,
    this.photoPath,
  });

  int get overall =>
      ((pace + shooting + passing + dribbling + defending + physical) / 6)
          .round();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'position': position,
        'pace': pace,
        'shooting': shooting,
        'passing': passing,
        'dribbling': dribbling,
        'defending': defending,
        'physical': physical,
        'photoPath': photoPath,
      };

  factory Player.fromMap(Map<String, dynamic> m) => Player(
        id: m['id'],
        name: m['name'],
        position: m['position'],
        pace: m['pace'],
        shooting: m['shooting'],
        passing: m['passing'],
        dribbling: m['dribbling'],
        defending: m['defending'],
        physical: m['physical'],
        photoPath: m['photoPath'],
      );
}
