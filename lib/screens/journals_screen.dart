import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/journal_provider.dart';
import '../widgets/journal_card.dart';
import '../theme/app_theme.dart';
import 'add_edit_journal_screen.dart';

class JournalsScreen extends StatelessWidget {
  const JournalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Thoughts'),
      ),
      body: Consumer<JournalProvider>(
        builder: (context, journalProvider, _) {
          final journals = journalProvider.journals;
          
          return Column(
            children: [
              // Add journal button at top
              Container(
                margin: const EdgeInsets.all(AppTheme.spacingM),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddEditJournalScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingM,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.surfaceVariantDark
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.surfaceVariantDark
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Text(
                          'What is on your mind?',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Journal list
              Expanded(
                child: journals.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                        itemCount: journals.length,
                        itemBuilder: (context, index) {
                          final journal = journals[index];
                          return JournalCard(
                            journal: journal,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditJournalScreen(journal: journal),
                                ),
                              );
                            },
                            onDelete: () {
                              journalProvider.deleteJournal(journal.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Journal entry deleted'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 80,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'No journal entries',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Capture your thoughts and reflections',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
