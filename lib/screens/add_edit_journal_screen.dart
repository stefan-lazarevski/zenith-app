import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal.dart';
import '../providers/journal_provider.dart';
import '../services/deepseek_service.dart';
import '../theme/app_theme.dart';

class AddEditJournalScreen extends StatefulWidget {
  final Journal? journal;

  const AddEditJournalScreen({super.key, this.journal});

  @override
  State<AddEditJournalScreen> createState() => _AddEditJournalScreenState();
}

class _AddEditJournalScreenState extends State<AddEditJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedEmoji;
  bool _isAnalyzing = false;
  bool _showEmojiPicker = false;
  DeepSeekService? _deepSeekService;

  final List<String> _moodEmojis = [
    '😊', // Happy
    '😔', // Sad
    '😰', // Stressed
    '😤', // Angry
    '🤔', // Thoughtful
    '😴', // Tired
    '🎉', // Excited
    '☕', // Peaceful
    '😐', // Neutral
    '🥰', // Loved
    '💪', // Motivated
    '😢', // Upset
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.journal?.title ?? '');
    _contentController = TextEditingController(text: widget.journal?.content ?? '');
    _selectedEmoji = widget.journal?.sentimentEmoji ?? '😊';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.journal != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Journal' : 'New Entry'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteJournal,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Give your entry a title',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please add a title';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
              autofocus: !isEditing,
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Mood emoji selector header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'How are you feeling?',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.surfaceVariantDark
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        _selectedEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                        });
                      },
                      icon: Icon(
                        _showEmojiPicker ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                      ),
                      label: Text(_showEmojiPicker ? 'Hide' : 'Change'),
                    ),
                    TextButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeMood,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.psychology, size: 18),
                      label: Text(_isAnalyzing ? 'Analyzing...' : 'AI Suggest'),
                    ),
                  ],
                ),
              ],
            ),
            
            // Emoji picker (collapsible)
            if (_showEmojiPicker) ...[
              const SizedBox(height: AppTheme.spacingM),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.surfaceVariantDark
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: _moodEmojis.map((emoji) {
                    final isSelected = _selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmoji = emoji;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          border: isSelected
                              ? Border.all(color: AppTheme.primary, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: AppTheme.spacingL),

            // Content field
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Journal Entry',
                hintText: 'What\'s on your mind?',
                alignLabelWithHint: true,
              ),
              maxLines: 12,
              minLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please write something';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
              autofocus: !isEditing,
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Save button
            FilledButton(
              onPressed: _saveJournal,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                child: Text(isEditing ? 'Update Entry' : 'Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveJournal() {
    if (_formKey.currentState!.validate()) {
      final journalProvider = context.read<JournalProvider>();

      if (widget.journal != null) {
        // Update existing journal
        journalProvider.updateJournal(
          widget.journal!.copyWith(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            sentimentEmoji: _selectedEmoji,
          ),
        );
      } else {
        // Create new journal
        journalProvider.addJournal(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          sentimentEmoji: _selectedEmoji,
        );
      }

      Navigator.pop(context);
    }
  }

  void _deleteJournal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this journal entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<JournalProvider>().deleteJournal(widget.journal!.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeMood() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something first!')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      _deepSeekService ??= DeepSeekService();
      final suggestedEmoji = await _deepSeekService!.analyzeSentiment(content);
      setState(() {
        _selectedEmoji = suggestedEmoji;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to analyze mood')),
        );
      }
    }
  }
}
