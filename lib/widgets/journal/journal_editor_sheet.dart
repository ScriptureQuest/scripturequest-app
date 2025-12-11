import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:level_up_your_faith/models/journal_entry.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';

class JournalEditorSheet extends StatefulWidget {
  final JournalEntry? entry;
  // Optional initial values for create mode (entry == null)
  final String? initialTitle;
  final String? initialBody;
  final List<String>? initialTags;
  // Verse link (create mode)
  final String? initialLinkedRef;
  final String? initialLinkedRefRoute;
    // Questline context (optional): if provided in create mode, saving will auto-complete the step
    final String? questlineId;
    final String? stepId;

  const JournalEditorSheet({
    super.key,
    this.entry,
    this.initialTitle,
    this.initialBody,
    this.initialTags,
    this.initialLinkedRef,
    this.initialLinkedRefRoute,
      this.questlineId,
      this.stepId,
  });

  @override
  State<JournalEditorSheet> createState() => _JournalEditorSheetState();
}

class _JournalEditorSheetState extends State<JournalEditorSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final Set<String> _selectedTags = <String>{};
  bool _isPinned = false;
  String? _linkedRef; // read-only display + save on create
  String? _linkedRefRoute;

  static const List<String> _tagOptions = <String>[
    'Prayer',
    'Gratitude',
    'Study',
    'Sermon',
    'Notes',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      _titleController.text = (e.title ?? '').trim();
      _bodyController.text = e.reflectionText;
      _selectedTags.addAll(e.tags);
      _isPinned = e.isPinned;
      _linkedRef = e.linkedRef;
      _linkedRefRoute = e.linkedRefRoute;
    } else {
      // Apply optional initial values for create mode
      if ((widget.initialTitle ?? '').trim().isNotEmpty) {
        _titleController.text = widget.initialTitle!.trim();
      }
      if ((widget.initialBody ?? '').trim().isNotEmpty) {
        _bodyController.text = widget.initialBody!;
      }
      if (widget.initialTags != null && widget.initialTags!.isNotEmpty) {
        _selectedTags.addAll(widget.initialTags!);
      }
      if ((widget.initialLinkedRef ?? '').trim().isNotEmpty) {
        _linkedRef = widget.initialLinkedRef!.trim();
      }
      if ((widget.initialLinkedRefRoute ?? '').trim().isNotEmpty) {
        _linkedRefRoute = widget.initialLinkedRefRoute!.trim();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final t = _titleController.text.trim();
    final b = _bodyController.text.trim();
    return t.isNotEmpty || b.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEditing = widget.entry != null;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(isEditing ? Icons.edit_note_rounded : Icons.note_add_rounded, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Entry' : 'New Entry',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: cs.onSurface.withValues(alpha: 0.7)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              // Title
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: 'Title',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.6)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              if ((_linkedRef ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                _LinkedVerseRow(ref: _linkedRef!, route: _linkedRefRoute),
              ],
              const SizedBox(height: 12),
              // Tags
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Tags (optional)', style: theme.textTheme.labelMedium),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tagOptions.map((tag) {
                  final selected = _selectedTags.contains(tag);
                  return ChoiceChip(
                    label: Text(tag),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: selected ? cs.onPrimary : theme.textTheme.labelSmall?.color,
                    ),
                    selectedColor: cs.primary,
                    backgroundColor: cs.surfaceContainerHighest,
                    side: BorderSide(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.25)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Pin toggle
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  title: Text('Pin this entry', style: theme.textTheme.bodyMedium),
                  subtitle: Text('Pinned entries stay at the top', style: theme.textTheme.labelSmall),
                  secondary: Icon(
                    _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: cs.primary,
                  ),
                  value: _isPinned,
                  onChanged: (v) => setState(() => _isPinned = v),
                ),
              ),
              const SizedBox(height: 12),
              // Body
              TextField(
                controller: _bodyController,
                textInputAction: TextInputAction.newline,
                maxLines: null,
                minLines: 8,
                decoration: InputDecoration(
                  hintText: 'Write your thoughts, prayers, or study notes...',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.6)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                        foregroundColor: theme.colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canSave
                          ? () async {
                              final provider = context.read<AppProvider>();
                              if (widget.entry == null) {
                                await provider.createJournalEntry(
                                  title: _titleController.text,
                                  body: _bodyController.text,
                                  tags: _selectedTags.toList(),
                                  isPinned: _isPinned,
                                  linkedRef: _linkedRef,
                                  linkedRefRoute: _linkedRefRoute,
                                );
                                 // If launched from a questline JOURNAL step, auto-complete the step
                                 if ((widget.questlineId ?? '').isNotEmpty && (widget.stepId ?? '').isNotEmpty) {
                                   try {
                                     provider.recordQuestStepInteraction(widget.questlineId!, widget.stepId!, 'journalSaved');
                                   } catch (e) {
                                     // ignore
                                   }
                                   await provider.markQuestlineStepDone(widget.questlineId!, widget.stepId!, stepXp: 25);
                                 }
                              } else {
                                await provider.updateJournalEntry(
                                  original: widget.entry!,
                                  title: _titleController.text,
                                  body: _bodyController.text,
                                  tags: _selectedTags.toList(),
                                  isPinned: _isPinned,
                                  // Preserve link (v1.0): do not change unless provided
                                );
                              }
                              // Mark Guided Start journal milestone
                              try {
                                await provider.markFirstJournalDone();
                              } catch (e) {
                                // ignore
                              }
                              // Toast confirmation (bottom-sheet-aware via external controller)
                              RewardToast.showSuccess(context, title: 'Saved to your journal.');
                              if (mounted) Navigator.of(context).pop(true);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save'),
                    ),
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

class _LinkedVerseRow extends StatelessWidget {
  final String ref;
  final String? route;
  const _LinkedVerseRow({required this.ref, this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: () {
        final r = (route ?? '/verses?ref=${Uri.encodeComponent(ref)}').trim();
        if (r.isNotEmpty) context.push(r);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.menu_book_rounded, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Linked verse: $ref',
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Go to passage',
              style: theme.textTheme.labelLarge?.copyWith(color: cs.primary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded, size: 18, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
