import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/task_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          // Profile header
          _buildProfileHeader(context),
          
          const SizedBox(height: AppTheme.spacingXl),
          
          // Analytics section
          Text(
            'Your Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Task completion this week
          _buildThisWeekCard(context),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Weekly completion bar chart
          _buildWeeklyChartCard(context),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Category pie chart
          _buildCategoryChartCard(context),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Mood this week
          _buildMoodCard(context),
          
          const SizedBox(height: AppTheme.spacingXl),
          
          // Sign Out button
          _buildSignOutButton(context),
          
          const SizedBox(height: AppTheme.spacingL),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    auth.userInitial,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingL),
                
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.userEmail,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Consumer2<TaskProvider, JournalProvider>(
                        builder: (context, taskProvider, journalProvider, _) {
                          return Text(
                            '${taskProvider.tasks.length} tasks • ${journalProvider.journals.length} journals',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    context.read<AuthProvider>().signOut();
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back from profile
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.error,
                  ),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout, color: AppTheme.error),
        label: const Text(
          'Sign Out',
          style: TextStyle(color: AppTheme.error),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.error.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
      ),
    );
  }

  Widget _buildThisWeekCard(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        
        final weekTasks = taskProvider.tasks.where((task) {
          return task.createdAt.isAfter(weekStart) && 
                 task.createdAt.isBefore(weekEnd);
        }).toList();
        
        final completedCount = weekTasks.where((t) => t.isCompleted).length;
        final totalCount = weekTasks.length;
        final completionRate = totalCount > 0 ? completedCount / totalCount : 0.0;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingM),
                
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    minHeight: 12,
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.surfaceVariantDark
                        : AppTheme.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingM),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount / $totalCount tasks',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${(completionRate * 100).toInt()}%',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChartCard(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final now = DateTime.now();
        final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        
        // Calculate completed tasks for each day of the week
        final weekData = List.generate(7, (index) {
          final day = now.subtract(Duration(days: now.weekday - 1 - index));
          final dayStart = DateTime(day.year, day.month, day.day);
          final dayEnd = dayStart.add(const Duration(days: 1));
          
          final completedCount = taskProvider.tasks.where((task) {
            return task.isCompleted &&
                   task.createdAt.isAfter(dayStart) &&
                   task.createdAt.isBefore(dayEnd);
          }).length;
          
          return completedCount.toDouble();
        });
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasks Completed This Week',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingL),
                
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < 7) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    weekDays[value.toInt()],
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(7, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: weekData[index],
                              color: AppTheme.primary,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChartCard(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final categoryData = <String, int>{};
        final categoryColors = {
          '🎓 College': Colors.blue.shade400,
          '💼 Work': Colors.purple.shade400,
          '🏠 Personal': Colors.green.shade400,
          '🛒 Shopping': Colors.orange.shade400,
        };
        
        // Count tasks by category
        for (var task in taskProvider.tasks) {
          categoryData[task.category] = (categoryData[task.category] ?? 0) + 1;
        }
        
        if (categoryData.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                children: [
                  Text(
                    'Task Categories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Text(
                    'No tasks yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        final total = categoryData.values.fold(0, (a, b) => a + b);
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Categories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingL),
                
                // Pie chart
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: categoryData.entries.map((entry) {
                        final percentage = (entry.value / total * 100).toInt();
                        return PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: '$percentage%',
                          color: categoryColors[entry.key] ?? Colors.grey,
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // Legend - vertical list
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categoryData.entries.map((entry) {
                    final percentage = (entry.value / total * 100).toInt();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: categoryColors[entry.key] ?? Colors.grey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Text(
                            '$percentage%',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodCard(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, journalProvider, _) {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        
        // Get last 7 days of moods
        final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final moodData = <String, String>{};
        
        for (int i = 0; i < 7; i++) {
          final day = weekStart.add(Duration(days: i));
          final dayStart = DateTime(day.year, day.month, day.day);
          final dayEnd = dayStart.add(const Duration(days: 1));
          
          final dayJournals = journalProvider.journals.where((j) {
            return j.timestamp.isAfter(dayStart) && j.timestamp.isBefore(dayEnd);
          }).toList();
          
          if (dayJournals.isNotEmpty) {
            moodData[weekDays[i]] = dayJournals.last.sentimentEmoji;
          }
        }
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood This Week',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingL),
                
                if (moodData.isEmpty)
                  Center(
                    child: Text(
                      'No journal entries this week',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // First row: Mon-Fri
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: weekDays.take(5).map((day) {
                          return Column(
                            children: [
                              Text(
                                day,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: AppTheme.spacingS),
                              Text(
                                moodData[day] ?? '—',
                                style: const TextStyle(fontSize: 32),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: AppTheme.spacingL),
                      
                      // Second row: Sat-Sun
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const Spacer(flex: 3),
                          ...weekDays.skip(5).map((day) {
                            return Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Text(
                                    day,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: AppTheme.spacingS),
                                  Text(
                                    moodData[day] ?? '—',
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const Spacer(flex: 3),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
