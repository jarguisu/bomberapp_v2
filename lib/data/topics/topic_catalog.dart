class TopicRef {
  final String blockId; // G, E o S
  final String topicCode; // G1, G2, E1...
  final String topicId; // ID del tema en el temario/convocatoria
  final String topicName; // Texto visible
  final String entityId; // GEN, CONSVAL...
  final String entityName; // Nombre largo de la entidad
  final String syllabusId; // GEN_CV, CONSVAL_2024...
  final String syllabusName; // Nombre largo del temario

  const TopicRef({
    required this.blockId,
    required this.topicCode,
    required this.topicId,
    required this.topicName,
    required this.entityId,
    required this.entityName,
    required this.syllabusId,
    required this.syllabusName,
  });

  String get label => '$topicCode - $topicName';
}

class TopicBlock {
  final String id; // Bloque G/E/S
  final String label; // "Bloque General", "Bloque Específico"...
  final List<TopicRef> topics;

  const TopicBlock({
    required this.id,
    required this.label,
    required this.topics,
  });
}

// Temas disponibles por bloque/entidad/convocatoria
const List<TopicBlock> topicBlocks = [
  TopicBlock(
    id: 'G',
    label: 'Bloque General',
    topics: [
      TopicRef(
        blockId: 'G',
        topicCode: 'G1',
        topicId: 'GEN_CV_G1',
        topicName: 'Constitución',
        entityId: 'GEN',
        entityName: 'Genérico Comunidad Valenciana',
        syllabusId: 'GEN_CV',
        syllabusName: 'Temario genérico Bombero CV',
      ),
      TopicRef(
        blockId: 'G',
        topicCode: 'G2',
        topicId: 'GEN_CV_G2',
        topicName: 'Estatuto de Autonomía',
        entityId: 'GEN',
        entityName: 'Genérico Comunidad Valenciana',
        syllabusId: 'GEN_CV',
        syllabusName: 'Temario genérico Bombero CV',
      ),
      TopicRef(
        blockId: 'G',
        topicCode: 'G3',
        topicId: 'GEN_CV_G3',
        topicName: 'Bases del Régimen Local (Ley 7/1985)',
        entityId: 'GEN',
        entityName: 'Genérico Comunidad Valenciana',
        syllabusId: 'GEN_CV',
        syllabusName: 'Temario genérico Bombero CV',
      ),
      TopicRef(
        blockId: 'G',
        topicCode: 'G4',
        topicId: 'GEN_CV_G4',
        topicName: 'Régimen local valenciano (Ley 8/2010)',
        entityId: 'GEN',
        entityName: 'Genérico Comunidad Valenciana',
        syllabusId: 'GEN_CV',
        syllabusName: 'Temario genérico Bombero CV',
      ),
    ],
  ),
  TopicBlock(
    id: 'S',
    label: 'Bloque Servicio',
    topics: [
      TopicRef(
        blockId: 'S',
        topicCode: 'S1',
        topicId: 'GEN_S1',
        topicName: 'Servicio: pruebas internas',
        entityId: 'GEN',
        entityName: 'Genérico',
        syllabusId: 'GEN',
        syllabusName: 'Genérico',
      ),
    ],
  ),
];
