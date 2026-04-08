class SafetyTimerState {
  const SafetyTimerState({
    required this.durationMinutes,
    required this.startedAt,
    required this.endsAt,
  });

  final int durationMinutes;
  final DateTime startedAt;
  final DateTime endsAt;

  factory SafetyTimerState.fromMap(Map<String, dynamic> map) {
    return SafetyTimerState(
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 15,
      startedAt:
          DateTime.tryParse(map['startedAt'] as String? ?? '') ??
          DateTime.now(),
      endsAt:
          DateTime.tryParse(map['endsAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'durationMinutes': durationMinutes,
      'startedAt': startedAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
    };
  }

  Duration remainingAt(DateTime now) {
    final Duration remaining = endsAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
