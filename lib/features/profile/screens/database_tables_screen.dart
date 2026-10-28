import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/widgets/custom_card.dart';

class DatabaseTablesScreen extends StatefulWidget {
  const DatabaseTablesScreen({super.key});

  @override
  State<DatabaseTablesScreen> createState() => _DatabaseTablesScreenState();
}

class _DatabaseTablesScreenState extends State<DatabaseTablesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = true;
  String _searchQuery = '';
  List<Map<String, dynamic>> _tablesInfo = [];

  final List<Map<String, dynamic>> _knownTables = [
    {'name': 'student_profile', 'label': 'Student Profile', 'icon': Icons.person_rounded},
    {'name': 'skills', 'label': 'Skills', 'icon': Icons.psychology_rounded},
    {'name': 'certificates', 'label': 'Certificates', 'icon': Icons.verified_rounded},
    {'name': 'projects', 'label': 'Projects', 'icon': Icons.folder_rounded},
    {'name': 'tasks', 'label': 'Tasks & To-Dos', 'icon': Icons.check_circle_rounded},
    {'name': 'learning_goals', 'label': 'Learning Goals', 'icon': Icons.flag_rounded},
    {'name': 'placement_topics', 'label': 'Placement Topics', 'icon': Icons.track_changes_rounded},
    {'name': 'interview_questions', 'label': 'Interview Questions', 'icon': Icons.quiz_rounded},
    {'name': 'job_applications', 'label': 'Job Applications', 'icon': Icons.business_center_rounded},
    {'name': 'education', 'label': 'Education', 'icon': Icons.school_rounded},
    {'name': 'achievements', 'label': 'Achievements', 'icon': Icons.emoji_events_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadTableCounts();
  }

  Future<void> _loadTableCounts() async {
    setState(() => _isLoading = true);
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = [];

    for (final table in _knownTables) {
      final name = table['name'] as String;
      int count = 0;
      try {
        final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $name');
        count = Sqflite.firstIntValue(countResult) ?? 0;
      } catch (_) {}

      results.add({
        ...table,
        'count': count,
      });
    }

    if (mounted) {
      setState(() {
        _tablesInfo = results;
        _isLoading = false;
      });
    }
  }

  void _viewTableData(String tableName, String label) async {
    final db = await _dbHelper.database;
    final rows = await db.query(tableName, limit: 100);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${rows.length} records',
                          style: const TextStyle(
                            color: AppColors.secondaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: rows.isEmpty
                        ? const Center(
                            child: Text(
                              'No records found in this table.',
                              style: TextStyle(color: AppColors.mutedText),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: rows.length,
                            separatorBuilder: (context, i) => const Divider(
                              color: AppColors.border,
                              height: 16,
                            ),
                            itemBuilder: (context, i) {
                              final row = rows[i];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: row.entries.map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 130,
                                          child: Text(
                                            e.key,
                                            style: const TextStyle(
                                              color: AppColors.secondaryAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${e.value ?? "null"}',
                                            style: const TextStyle(
                                              color: AppColors.primaryText,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _tablesInfo.where((t) {
      final name = (t['name'] as String).toLowerCase();
      final label = (t['label'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || label.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Database Tables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTableCounts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar matching mockup Screen 16
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search database tables...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mutedText),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final table = filtered[index];
                      final name = table['name'] as String;
                      final label = table['label'] as String;
                      final count = table['count'] as int;
                      final icon = table['icon'] as IconData;

                      return CustomCard(
                        onTap: () => _viewTableData(name, label),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.elevatedSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: AppColors.primaryAccent, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                '$count records',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: count > 0
                                      ? AppColors.secondaryAccent
                                      : AppColors.mutedText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.mutedText,
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
