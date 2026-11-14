import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/note_model.dart';
import '../../../models/planner_event.dart';
import '../../../repositories/notes_repository.dart';
import '../../../repositories/planner_repository.dart';
import '../widgets/add_edit_note_dialog.dart';
import '../widgets/add_edit_event_dialog.dart';
import '../widgets/note_reader_dialog.dart';

class NotesPlannerHubScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? preselectedSkillFilter;
  final List<NoteModel>? initialNotes;
  final List<PlannerEvent>? initialEvents;

  const NotesPlannerHubScreen({
    super.key,
    this.initialTabIndex = 0,
    this.preselectedSkillFilter,
    this.initialNotes,
    this.initialEvents,
  });

  @override
  State<NotesPlannerHubScreen> createState() => _NotesPlannerHubScreenState();
}

class _NotesPlannerHubScreenState extends State<NotesPlannerHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Repositories
  final NotesRepository _notesRepo = NotesRepository();
  final PlannerRepository _plannerRepo = PlannerRepository();

  // Notes state
  final TextEditingController _notesSearchController = TextEditingController();
  List<NoteModel> _notes = [];
  String _selectedNoteCategory = 'All';
  bool _isLoadingNotes = true;

  // Planner state
  List<PlannerEvent> _selectedDayEvents = [];
  List<PlannerEvent> _upcomingCountdowns = [];
  late DateTime _selectedDate;
  String _selectedEventType = 'All';
  bool _isLoadingPlanner = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _selectedDate = DateTime.now();

    if (widget.initialNotes != null) {
      _notes = widget.initialNotes!;
      _isLoadingNotes = false;
    } else {
      _loadNotes();
    }

    if (widget.initialEvents != null) {
      _selectedDayEvents = widget.initialEvents!;
      _upcomingCountdowns = widget.initialEvents!;
      _isLoadingPlanner = false;
    } else {
      _loadPlanner();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesSearchController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Notes Logic
  // ===========================================================================

  Future<void> _loadNotes() async {
    setState(() => _isLoadingNotes = true);
    final results = await _notesRepo.getAllNotes(
      category: _selectedNoteCategory,
      searchQuery: _notesSearchController.text,
      linkedSkillName: widget.preselectedSkillFilter,
    );
    if (mounted) {
      setState(() {
        _notes = results;
        _isLoadingNotes = false;
      });
    }
  }

  Future<void> _addNote() async {
    final newNote = await showDialog<NoteModel>(
      context: context,
      builder: (ctx) => AddEditNoteDialog(
        preselectedSkillName: widget.preselectedSkillFilter,
      ),
    );

    if (newNote != null) {
      await _notesRepo.addNote(newNote);
      _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note created successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editNote(NoteModel note) async {
    final updated = await showDialog<NoteModel>(
      context: context,
      builder: (ctx) => AddEditNoteDialog(note: note),
    );

    if (updated != null) {
      await _notesRepo.updateNote(updated);
      _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleNotePin(NoteModel note) async {
    await _notesRepo.togglePin(note.id!, note.isPinned);
    _loadNotes();
  }

  Future<void> _deleteNote(NoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Delete Note',
            style: TextStyle(color: AppColors.primaryText)),
        content: Text('Are you sure you want to delete "${note.title}"?',
            style: const TextStyle(color: AppColors.secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notesRepo.deleteNote(note.id!);
      _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openNoteReader(NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => NoteReaderDialog(
        note: note,
        onNoteChanged: _loadNotes,
      ),
    );
  }

  // ===========================================================================
  // Planner Logic
  // ===========================================================================

  Future<void> _loadPlanner() async {
    setState(() => _isLoadingPlanner = true);

    final selectedDateStr = _selectedDate.toIso8601String().split('T').first;
    final dayEvents = await _plannerRepo.getAllEvents(
      targetDate: selectedDateStr,
      eventType: _selectedEventType,
    );
    final upcoming = await _plannerRepo.getUpcomingEvents(limit: 6);

    if (mounted) {
      setState(() {
        _selectedDayEvents = dayEvents;
        _upcomingCountdowns = upcoming;
        _isLoadingPlanner = false;
      });
    }
  }

  Future<void> _addEvent() async {
    final selectedDateStr = _selectedDate.toIso8601String().split('T').first;
    final newEvent = await showDialog<PlannerEvent>(
      context: context,
      builder: (ctx) => AddEditEventDialog(initialDate: selectedDateStr),
    );

    if (newEvent != null) {
      await _plannerRepo.addEvent(newEvent);
      _loadPlanner();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event scheduled successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editEvent(PlannerEvent event) async {
    final updated = await showDialog<PlannerEvent>(
      context: context,
      builder: (ctx) => AddEditEventDialog(event: event),
    );

    if (updated != null) {
      await _plannerRepo.updateEvent(updated);
      _loadPlanner();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _toggleEventComplete(PlannerEvent event) async {
    await _plannerRepo.toggleEventCompleted(event.id!, event.isCompleted);
    _loadPlanner();
  }

  Future<void> _deleteEvent(PlannerEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Delete Event',
            style: TextStyle(color: AppColors.primaryText)),
        content: Text('Are you sure you want to delete "${event.title}"?',
            style: const TextStyle(color: AppColors.secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _plannerRepo.deleteEvent(event.id!);
      _loadPlanner();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  Color _resolveTagColor(String tag) {
    switch (tag) {
      case 'blue':
        return const Color(0xFF38BDF8);
      case 'emerald':
        return const Color(0xFF34D399);
      case 'amber':
        return const Color(0xFFFBBF24);
      case 'rose':
        return const Color(0xFFFB7185);
      case 'purple':
      default:
        return AppColors.primaryPurple;
    }
  }

  Color _resolveEventTypeColor(String type) {
    switch (type) {
      case 'Placement Drive':
        return const Color(0xFFC084FC);
      case 'Exam / Test':
        return const Color(0xFFFB7185);
      case 'Mock Interview':
        return const Color(0xFF38BDF8);
      case 'Revision':
        return const Color(0xFF34D399);
      case 'Study Sprint':
      default:
        return AppColors.primaryPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppColors.mainBackground,
        elevation: 0,
        title: const Text(
          'Notes & Planner',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.secondaryText,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(
              icon: Icon(Icons.note_alt_rounded, size: 20),
              text: 'Notes & Cheatsheets',
            ),
            Tab(
              icon: Icon(Icons.calendar_month_rounded, size: 20),
              text: 'Study & Placement Planner',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotesTab(),
          _buildPlannerTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        onPressed: () {
          if (_tabController.index == 0) {
            _addNote();
          } else {
            _addEvent();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return Text(
              _tabController.index == 0 ? 'Add Note' : 'Schedule Event',
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // Notes Tab View
  // ===========================================================================

  Widget _buildNotesTab() {
    final pinnedNotes = _notes.where((n) => n.isPinned).toList();
    final otherNotes = _notes.where((n) => !n.isPinned).toList();

    return RefreshIndicator(
      color: AppColors.primaryPurple,
      backgroundColor: AppColors.cardBackground,
      onRefresh: _loadNotes,
      child: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchFilterBar(
              controller: _notesSearchController,
              hintText: 'Search notes, code snippets, DSA tricks...',
              onChanged: (_) => _loadNotes(),
            ),
          ),

          // Categories horizontally scrollable chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNoteCategoryChip('All'),
                ...NoteModel.categories.map((c) => _buildNoteCategoryChip(c)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Notes List
          Expanded(
            child: _isLoadingNotes
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryPurple),
                  )
                : _notes.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.note_outlined,
                        title: _notesSearchController.text.isNotEmpty ||
                                _selectedNoteCategory != 'All'
                            ? 'No Matching Notes Found'
                            : 'No Revision Notes Yet',
                        description: _notesSearchController.text.isNotEmpty ||
                                _selectedNoteCategory != 'All'
                            ? 'Try clearing the search or category filter.'
                            : 'Save important code snippets, interview pointers, algorithms, and cheatsheets.',
                        actionLabel: 'Add First Note',
                        onAction: _addNote,
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        children: [
                          if (pinnedNotes.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.push_pin,
                                    size: 14, color: AppColors.lightPurple),
                                const SizedBox(width: 6),
                                Text(
                                  'PINNED CHEATSHEETS (${pinnedNotes.length})',
                                  style: const TextStyle(
                                    color: AppColors.lightPurple,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...pinnedNotes.map((n) => _buildNoteCard(n)),
                            const SizedBox(height: 12),
                            if (otherNotes.isNotEmpty)
                              const Text(
                                'ALL NOTES',
                                style: TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                          ...otherNotes.map((n) => _buildNoteCard(n)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCategoryChip(String category) {
    final isSelected = _selectedNoteCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(category),
        selectedColor: AppColors.secondaryCard,
        backgroundColor: AppColors.cardBackground,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.lightPurple : AppColors.secondaryText,
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primaryPurple : AppColors.border,
          width: isSelected ? 1.2 : 0.8,
        ),
        onSelected: (selected) {
          setState(() => _selectedNoteCategory = category);
          _loadNotes();
        },
      ),
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    final tagColor = _resolveTagColor(note.colorTag);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: note.isPinned
              ? AppColors.primaryPurple.withValues(alpha: 0.6)
              : AppColors.border,
          width: note.isPinned ? 1.2 : 0.8,
        ),
        boxShadow: note.isPinned
            ? [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openNoteReader(note),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with Category pill, Linked skill, and Pin/More actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: tagColor.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            note.category,
                            style: TextStyle(
                              color: tagColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (note.linkedSkillName != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryCard,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link,
                                    size: 11, color: AppColors.secondaryAccent),
                                const SizedBox(width: 3),
                                Text(
                                  note.linkedSkillName!,
                                  style: const TextStyle(
                                    color: AppColors.secondaryAccent,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            note.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            size: 17,
                            color: note.isPinned
                                ? AppColors.lightPurple
                                : AppColors.mutedText,
                          ),
                          onPressed: () => _toggleNotePin(note),
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.more_vert,
                              size: 18, color: AppColors.mutedText),
                          color: AppColors.secondaryCard,
                          onSelected: (action) {
                            if (action == 'edit') {
                              _editNote(note);
                            } else if (action == 'delete') {
                              _deleteNote(note);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit,
                                      size: 15, color: AppColors.secondaryText),
                                  SizedBox(width: 8),
                                  Text('Edit',
                                      style: TextStyle(
                                          color: AppColors.primaryText,
                                          fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 15, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(
                                          color: AppColors.error,
                                          fontSize: 12.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Note Title
                Text(
                  note.title,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Note Content Snippet
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                // Footer with Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Updated: ${note.updatedAt.split("T").first}',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11,
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'Read more',
                          style: TextStyle(
                            color: AppColors.lightPurple,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: AppColors.lightPurple),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Planner Tab View
  // ===========================================================================

  Widget _buildPlannerTab() {
    return RefreshIndicator(
      color: AppColors.primaryPurple,
      backgroundColor: AppColors.cardBackground,
      onRefresh: _loadPlanner,
      child: Column(
        children: [
          // 1. Interactive 14-Day Horizontal Date Strip
          _buildDateStrip(),

          // 2. Upcoming Milestones & Countdowns Carousel (if any exist)
          if (_upcomingCountdowns.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.flag_rounded,
                          color: AppColors.lightPurple, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'UPCOMING MILESTONES & DRIVES',
                        style: TextStyle(
                          color: AppColors.lightPurple,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_upcomingCountdowns.length} active',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 112,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _upcomingCountdowns.length,
                itemBuilder: (context, index) {
                  final event = _upcomingCountdowns[index];
                  return _buildCountdownCard(event);
                },
              ),
            ),
          ],

          const SizedBox(height: 8),

          // 3. Event Type Filter Chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildEventTypeChip('All'),
                ...PlannerEvent.eventTypes.map((t) => _buildEventTypeChip(t)),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 4. Daily Schedule Agenda for selected date
          Expanded(
            child: _isLoadingPlanner
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryPurple),
                  )
                : _selectedDayEvents.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.event_available_rounded,
                        title: 'No Events for This Day',
                        description:
                            'Schedule a placement drive, study session, or mock interview for this date.',
                        actionLabel: 'Schedule for Selected Day',
                        onAction: _addEvent,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                        itemCount: _selectedDayEvents.length,
                        itemBuilder: (context, index) {
                          final event = _selectedDayEvents[index];
                          return _buildEventItemCard(event);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    final now = DateTime.now();
    // 3 days back, 14 days forward
    final days = List.generate(18, (i) {
      return now.subtract(const Duration(days: 3)).add(Duration(days: i));
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: SizedBox(
        height: 64,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final date = days[index];
            final isSelected = date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day;
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            final dayName = _getDayName(date.weekday);

            return GestureDetector(
              onTap: () {
                setState(() => _selectedDate = date);
                _loadPlanner();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            AppColors.primaryPurple,
                            AppColors.brightAccent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isToday
                          ? AppColors.primaryPurple.withValues(alpha: 0.15)
                          : AppColors.secondaryCard),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : (isToday
                            ? AppColors.primaryPurple
                            : AppColors.border),
                    width: isSelected || isToday ? 1.2 : 0.8,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                ? AppColors.lightPurple
                                : AppColors.secondaryText),
                        fontSize: 10.5,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                ? AppColors.lightPurple
                                : AppColors.primaryText),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
      default:
        return 'Sun';
    }
  }

  Widget _buildCountdownCard(PlannerEvent event) {
    final typeColor = _resolveEventTypeColor(event.eventType);

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.eventType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.secondaryCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Text(
                  event.countdownLabel,
                  style: TextStyle(
                    color: event.isOverdue
                        ? AppColors.error
                        : AppColors.lightPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            event.title,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  event.targetDate,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (event.startTime != null)
                Flexible(
                  child: Text(
                    event.startTime!,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 10.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeChip(String type) {
    final isSelected = _selectedEventType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(type),
        selectedColor: AppColors.secondaryCard,
        backgroundColor: AppColors.cardBackground,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.lightPurple : AppColors.secondaryText,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primaryPurple : AppColors.border,
          width: isSelected ? 1.2 : 0.8,
        ),
        onSelected: (selected) {
          setState(() => _selectedEventType = type);
          _loadPlanner();
        },
      ),
    );
  }

  Widget _buildEventItemCard(PlannerEvent event) {
    final typeColor = _resolveEventTypeColor(event.eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: event.isCompleted
              ? AppColors.border.withValues(alpha: 0.5)
              : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editEvent(event),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                Checkbox(
                  value: event.isCompleted,
                  activeColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (_) => _toggleEventComplete(event),
                ),
                const SizedBox(width: 8),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              event.eventType,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryCard,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'Priority: ${event.priority}',
                              style: TextStyle(
                                color: event.priority == 'High'
                                    ? AppColors.error
                                    : AppColors.secondaryText,
                                fontSize: 9.5,
                                fontWeight: event.priority == 'High'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        event.title,
                        style: TextStyle(
                          color: event.isCompleted
                              ? AppColors.mutedText
                              : AppColors.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: event.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (event.description != null &&
                          event.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          event.description!,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (event.startTime != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 12, color: AppColors.lightPurple),
                            const SizedBox(width: 4),
                            Text(
                              event.endTime != null
                                  ? '${event.startTime} - ${event.endTime}'
                                  : event.startTime!,
                              style: const TextStyle(
                                color: AppColors.lightPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.mutedText),
                  onPressed: () => _deleteEvent(event),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
