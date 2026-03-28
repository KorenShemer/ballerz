class Player {
  final int? id;
  final String name;
  final String position;
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;

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
      };

  factory Player.fromMap(Map<String, dynamic> map) => Player(
        id: map['id'],
        name: map['name'],
        position: map['position'],
        pace: map['pace'],
        shooting: map['shooting'],
        passing: map['passing'],
        dribbling: map['dribbling'],
        defending: map['defending'],
        physical: map['physical'],
      );

  Player copyWith({
    int? id,
    String? name,
    String? position,
    int? pace,
    int? shooting,
    int? passing,
    int? dribbling,
    int? defending,
    int? physical,
  }) =>
      Player(
        id: id ?? this.id,
        name: name ?? this.name,
        position: position ?? this.position,
        pace: pace ?? this.pace,
        shooting: shooting ?? this.shooting,
        passing: passing ?? this.passing,
        dribbling: dribbling ?? this.dribbling,
        defending: defending ?? this.defending,
        physical: physical ?? this.physical,
      );
}