class TriviaModel {
  final String question;
  final Map<String, String> answers; // uid -> answer text

  const TriviaModel({
    required this.question,
    required this.answers,
  });

  factory TriviaModel.fromMap(Map<String, dynamic> map) {
    final rawAnswers = map['answers'] as Map<dynamic, dynamic>? ?? {};
    final Map<String, String> answers = {};
    rawAnswers.forEach((key, value) {
      answers[key.toString()] = value.toString();
    });
    return TriviaModel(
      question: map['question'] as String? ?? '',
      answers: answers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answers': answers,
    };
  }

  TriviaModel copyWith({
    String? question,
    Map<String, String>? answers,
  }) {
    return TriviaModel(
      question: question ?? this.question,
      answers: answers ?? this.answers,
    );
  }
}
