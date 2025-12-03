class TopicBlock {
  final String id;      // Por ejemplo: "A"
  final String label;   // Por ejemplo: "Bloque A"
  final List<String> topics;

  const TopicBlock({
    required this.id,
    required this.label,
    required this.topics,
  });
}

// Aquí defines todos los bloques y temas
const List<TopicBlock> topicBlocks = [
  TopicBlock(
    id: 'A',
    label: 'Bloque A',
    topics: [
      'A-01 Constitución y organización del Estado',
      'A-02 Estatuto de Autonomía CV',
      'A-03 Prevención y riesgos laborales',
    ],
  ),
  TopicBlock(
    id: 'B',
    label: 'Bloque B',
    topics: [
      'B-01 Agentes extintores',
      'B-02 Hidráulica básica',
      'B-03 Materiales y herramientas',
    ],
  ),
  TopicBlock(
    id: 'C',
    label: 'Bloque C',
    topics: [
      'C-01 Servicio y organización',
      'C-02 Procedimientos operativos',
    ],
  ),
];
