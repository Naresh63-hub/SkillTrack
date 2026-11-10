import '../core/database/database_helper.dart';
import '../models/ai_roadmap.dart';

class AiRoadmapRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<AiRoadmap?> getActiveRoadmap() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'ai_roadmaps',
      orderBy: 'updated_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final roadmap = AiRoadmap.fromMap(maps.first);
    final nodes = await getNodesForRoadmap(roadmap.id!);
    return roadmap.copyWith(nodes: nodes);
  }

  Future<AiRoadmap?> getRoadmapByRole(String targetRole) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'ai_roadmaps',
      where: 'LOWER(target_role) = ?',
      whereArgs: [targetRole.trim().toLowerCase()],
      orderBy: 'updated_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final roadmap = AiRoadmap.fromMap(maps.first);
    final nodes = await getNodesForRoadmap(roadmap.id!);
    return roadmap.copyWith(nodes: nodes);
  }

  Future<List<AiRoadmapNode>> getNodesForRoadmap(int roadmapId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'ai_roadmap_nodes',
      where: 'roadmap_id = ?',
      whereArgs: [roadmapId],
      orderBy: 'order_index ASC',
    );
    return maps.map((m) => AiRoadmapNode.fromMap(m)).toList();
  }

  Future<AiRoadmap> saveRoadmap({
    required AiRoadmap roadmap,
    required List<AiRoadmapNode> nodes,
  }) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // Check existing roadmap for role
      final existing = await txn.query(
        'ai_roadmaps',
        where: 'LOWER(target_role) = ?',
        whereArgs: [roadmap.targetRole.trim().toLowerCase()],
        limit: 1,
      );

      int roadmapId;
      if (existing.isNotEmpty) {
        roadmapId = existing.first['id'] as int;
        // Keep existing completed node statuses if they match
        final existingNodes = await txn.query(
          'ai_roadmap_nodes',
          where: 'roadmap_id = ?',
          whereArgs: [roadmapId],
        );
        final completedTitles = <String>{};
        for (final en in existingNodes) {
          if ((en['is_completed'] as int? ?? 0) == 1) {
            completedTitles
                .add((en['topic_title'] as String).toLowerCase().trim());
          }
        }

        await txn.update(
          'ai_roadmaps',
          roadmap.toMap()..remove('id'),
          where: 'id = ?',
          whereArgs: [roadmapId],
        );
        await txn.delete(
          'ai_roadmap_nodes',
          where: 'roadmap_id = ?',
          whereArgs: [roadmapId],
        );

        int completedCount = 0;
        final insertedNodes = <AiRoadmapNode>[];
        for (int i = 0; i < nodes.length; i++) {
          final n = nodes[i];
          final isAlreadyCompleted =
              completedTitles.contains(n.topicTitle.toLowerCase().trim());
          if (isAlreadyCompleted) completedCount++;

          final nodeMap = n
              .copyWith(
                roadmapId: roadmapId,
                orderIndex: i,
                isCompleted: isAlreadyCompleted,
              )
              .toMap()
            ..remove('id');

          final nodeId = await txn.insert('ai_roadmap_nodes', nodeMap);
          insertedNodes.add(n.copyWith(
            id: nodeId,
            roadmapId: roadmapId,
            orderIndex: i,
            isCompleted: isAlreadyCompleted,
          ));
        }

        final pct =
            nodes.isEmpty ? 0.0 : (completedCount / nodes.length) * 100.0;
        await txn.update(
          'ai_roadmaps',
          {'overall_progress': pct},
          where: 'id = ?',
          whereArgs: [roadmapId],
        );

        return roadmap.copyWith(
          id: roadmapId,
          overallProgress: pct,
          nodes: insertedNodes,
        );
      } else {
        roadmapId =
            await txn.insert('ai_roadmaps', roadmap.toMap()..remove('id'));
        final insertedNodes = <AiRoadmapNode>[];
        for (int i = 0; i < nodes.length; i++) {
          final n = nodes[i];
          final nodeMap = n
              .copyWith(
                roadmapId: roadmapId,
                orderIndex: i,
              )
              .toMap()
            ..remove('id');
          final nodeId = await txn.insert('ai_roadmap_nodes', nodeMap);
          insertedNodes.add(n.copyWith(
            id: nodeId,
            roadmapId: roadmapId,
            orderIndex: i,
          ));
        }

        return roadmap.copyWith(
          id: roadmapId,
          nodes: insertedNodes,
        );
      }
    });
  }

  Future<void> toggleNodeCompletion(int nodeId, bool isCompleted) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final nodeMaps = await txn.query(
        'ai_roadmap_nodes',
        where: 'id = ?',
        whereArgs: [nodeId],
        limit: 1,
      );
      if (nodeMaps.isEmpty) return;

      final node = AiRoadmapNode.fromMap(nodeMaps.first);
      final completedAt = isCompleted ? DateTime.now().toIso8601String() : null;

      await txn.update(
        'ai_roadmap_nodes',
        {
          'is_completed': isCompleted ? 1 : 0,
          'completed_at': completedAt,
        },
        where: 'id = ?',
        whereArgs: [nodeId],
      );

      // Recalculate roadmap overall progress
      final allNodes = await txn.query(
        'ai_roadmap_nodes',
        where: 'roadmap_id = ?',
        whereArgs: [node.roadmapId],
      );

      final total = allNodes.length;
      final completed =
          allNodes.where((m) => (m['is_completed'] as int? ?? 0) == 1).length;
      final pct = total > 0 ? (completed / total) * 100.0 : 0.0;

      await txn.update(
        'ai_roadmaps',
        {
          'overall_progress': pct,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [node.roadmapId],
      );
    });
  }
}
