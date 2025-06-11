class MeditationStep {
  final String title;
  final String description;
  final String audioFile;

  const MeditationStep({
    required this.title,
    required this.description,
    required this.audioFile,
  });
}

class MeditationSteps {
  static const List<MeditationStep> steps = [
    MeditationStep(
      title: 'Место вашей мечты',
      description: 'Представьте место, где вы чувствуете себя спокойно и защищённо. Это может быть реальное или воображаемое пространство.',
      audioFile: '1.mp3',
    ),
    MeditationStep(
      title: 'Время суток',
      description: 'Выберите время дня для вашего путешествия. Утро, день, вечер или ночь - когда вы чувствуете себя наиболее комфортно?',
      audioFile: '2.mp3',
    ),
    MeditationStep(
      title: 'Персонажи',
      description: 'Кто будет сопровождать вас в этом путешествии? Вы можете быть один или в компании близких людей.',
      audioFile: '3.mp3',
    ),
    MeditationStep(
      title: 'Эмоции',
      description: 'Какие чувства вы хотите испытать? Радость, спокойствие, вдохновение или что-то другое?',
      audioFile: '4.mp3',
    ),
    MeditationStep(
      title: 'Детали',
      description: 'Добавьте детали к вашему внутреннему миру. Звуки, запахи, текстуры - всё, что сделает опыт более живым.',
      audioFile: '5.mp3',
    ),
    MeditationStep(
      title: 'Стиль сна',
      description: 'Выберите стиль вашего сна. Реалистичный, фантастический, абстрактный - как вы видите свой внутренний мир?',
      audioFile: '6.mp3',
    ),
  ];
}