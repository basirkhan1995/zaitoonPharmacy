class SecurityQuestion {
  final int id;
  final String text;

  const SecurityQuestion({required this.id, required this.text});

  factory SecurityQuestion.fromJson(Map<String, dynamic> j) => SecurityQuestion(
    id:   (j['id'] as num).toInt(),
    text: j['text'] as String? ?? '',
  );
}