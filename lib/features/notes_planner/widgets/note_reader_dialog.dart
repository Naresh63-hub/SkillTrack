import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/note_model.dart';
import '../../../repositories/notes_repository.dart';
import 'add_edit_note_dialog.dart';

class NoteReaderDialog extends StatefulWidget {
  final NoteModel note;
  final VoidCallback? onNoteChanged;

  const NoteReaderDialog({
    super.key,
    required this.note,
    this.onNoteChanged,
  });

  @override
  State<NoteReaderDialog> createState() => _NoteReaderDialogState();
}

class _NoteReaderDialogState extends State<NoteReaderDialog> {
  final NotesRepository _repo = NotesRepository();
  late NoteModel _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
  }

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

  Future<void> _togglePin() async {
    await _repo.togglePin(_currentNote.id!, _currentNote.isPinned);
    final refreshed = await _repo.getNoteById(_currentNote.id!);
    if (refreshed != null && mounted) {
      setState(() => _currentNote = refreshed);
      widget.onNoteChanged?.call();
    }
  }

  Future<void> _editNote() async {
    final updated = await showDialog<NoteModel>(
      context: context,
      builder: (ctx) => AddEditNoteDialog(note: _currentNote),
    );

    if (updated != null) {
      await _repo.updateNote(updated);
      final refreshed = await _repo.getNoteById(_currentNote.id!);
      if (refreshed != null && mounted) {
        setState(() => _currentNote = refreshed);
        widget.onNoteChanged?.call();
      }
    }
  }

  Future<void> _deleteNote() async {
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
        content: Text(
            'Are you sure you want to delete "${_currentNote.title}"?',
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

    if (confirmed == true && mounted) {
      await _repo.deleteNote(_currentNote.id!);
      widget.onNoteChanged?.call();
      Navigator.of(context).pop();
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(
        text: '${_currentNote.title}\n\n${_currentNote.content}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = _resolveTagColor(_currentNote.colorTag);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: tagColor.withValues(alpha: 0.5), width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Chips & Pin
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: tagColor.withValues(alpha: 0.4),
                              width: 0.8),
                        ),
                        child: Text(
                          _currentNote.category,
                          style: TextStyle(
                            color: tagColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_currentNote.linkedSkillName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryCard,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.border, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.link,
                                  size: 12, color: AppColors.secondaryAccent),
                              const SizedBox(width: 4),
                              Text(
                                _currentNote.linkedSkillName!,
                                style: const TextStyle(
                                  color: AppColors.secondaryAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _currentNote.isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          color: _currentNote.isPinned
                              ? AppColors.lightPurple
                              : AppColors.mutedText,
                          size: 20,
                        ),
                        tooltip: _currentNote.isPinned ? 'Unpin' : 'Pin to top',
                        onPressed: _togglePin,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.mutedText, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                _currentNote.title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Updated: ${_currentNote.updatedAt.split("T").first}',
                style:
                    const TextStyle(color: AppColors.mutedText, fontSize: 11),
              ),
              const Divider(color: AppColors.border, height: 20),

              // Content Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _currentNote.content,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 13.5,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Footer Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondaryText,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 20),
                        tooltip: 'Delete Note',
                        onPressed: _deleteNote,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _editNote,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
