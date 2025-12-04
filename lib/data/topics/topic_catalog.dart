class TopicRef {
  final String id; // G1, G2, E1...
  final String label; // Lo que se ve en la app: "G1 - Constitución"

  const TopicRef({required this.id, required this.label});
}

class TopicBlock {
  final String id; // Por si luego tienes más bloques
  final String label; // "Bloque General", "Bloque A", etc.
  final List<TopicRef> topics;

  const TopicBlock({
    required this.id,
    required this.label,
    required this.topics,
  });
}

// De momento solo tenemos el tema G1 real en la BBDD.
const List<TopicBlock> topicBlocks = [
  TopicBlock(
    id: 'GENERAL',
    label: 'Bloque General',
    topics: [
      TopicRef(id: 'G1', label: 'G1 - Constitución'),
      TopicRef(id: 'G2', label: 'G2 - Estatuto de Autonomía'),
    ],
  ),
];
