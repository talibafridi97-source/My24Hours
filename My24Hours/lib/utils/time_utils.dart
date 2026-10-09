import '../models/activity.dart';

class TimeAccountingResult {
  final int accountedMinutes;
  final int remainingMinutes;
  final double accountingPercentage;
  final List<Activity> validActivities;
  final List<String> overlapWarnings;

  TimeAccountingResult({
    required this.accountedMinutes,
    required this.remainingMinutes,
    required this.accountingPercentage,
    required this.validActivities,
    required this.overlapWarnings,
  });
}

class TimeUtils {
  static const int totalDayMinutes = 1440;

  /// Process activities for a single day:
  /// - Validate intervals (0 <= start < end <= 1440)
  /// - Detect overlaps and duplicate/conflicting time
  /// - Calculate total unique accounted minutes and percentage
  static TimeAccountingResult calculateTimeAccounting(List<Activity> activities) {
    List<Activity> validActivities = [];
    List<String> warnings = [];

    // Sort by startMinute
    final sorted = List<Activity>.from(activities);
    sorted.sort((a, b) => a.startMinute.compareTo(b.startMinute));

    int lastEnd = -1;
    for (var act in sorted) {
      if (act.startMinute < 0 || act.endMinute > totalDayMinutes || act.startMinute >= act.endMinute) {
        warnings.pushIfNotNull('Invalid time range for "${act.title}" (${_formatTime(act.startMinute)} - ${_formatTime(act.endMinute)})');
        continue;
      }

      // Check overlap with previous accepted activity
      if (act.startMinute < lastEnd) {
        warnings.add('Overlapping time detected for "${act.title}" (${_formatTime(act.startMinute)} - ${_formatTime(act.endMinute)}). Overlap adjusted for accounting.');
        // If it fully overlaps or partially overlaps, we can merge or take non-overlapping part,
        // but standard interval merge:
        if (act.endMinute > lastEnd) {
          // Part of it is new
          int effectiveStart = lastEnd;
          int effectiveDuration = act.endMinute - effectiveStart;
          // create a sub-activity or adjust accounted minutes
          validActivities.add(Activity(
            id: act.id,
            title: act.title,
            category: act.category,
            date: act.date,
            startMinute: effectiveStart,
            endMinute: act.endMinute,
            durationMinutes: effectiveDuration,
          ));
          lastEnd = act.endMinute;
        } else {
          // Completely contained within previous interval, fully duplicate/overlap
          // 0 added to accounted minutes
        }
      } else {
        validActivities.add(act);
        lastEnd = act.endMinute;
      }
    }

    // Now calculate merged accounted minutes properly using interval merging
    int accountedMinutes = 0;
    List<List<int>> intervals = [];
    for (var act in sorted) {
      if (act.startMinute >= 0 && act.endMinute <= totalDayMinutes && act.startMinute < act.endMinute) {
        intervals.add([act.startMinute, act.endMinute]);
      }
    }

    // Merge intervals
    if (intervals.isNotEmpty) {
      intervals.sort((a, b) => a[0].compareTo(b[0]));
      List<List<int>> merged = [intervals[0]];
      for (int i = 1; i < intervals.length; i++) {
        var current = intervals[i];
        var last = merged.last;
        if (current[0] < last[1]) {
          // Overlap
          last[1] = last[1] > current[1] ? last[1] : current[1];
        } else {
          merged.add(current);
        }
      }
      for (var m in merged) {
        accountedMinutes += (m[1] - m[0]);
      }
    }

    int remainingMinutes = totalDayMinutes - accountedMinutes;
    if (remainingMinutes < 0) remainingMinutes = 0;
    if (accountedMinutes > totalDayMinutes) accountedMinutes = totalDayMinutes;

    double percentage = (accountedMinutes / totalDayMinutes) * 100.0;

    return TimeAccountingResult(
      accountedMinutes: accountedMinutes,
      remainingMinutes: remainingMinutes,
      accountingPercentage: percentage,
      validActivities: validActivities,
      overlapWarnings: warnings,
    );
  }

  /// Calculate Productivity Score out of 100 based on category goals and actual activity durations
  static double calculateProductivityScore(List<Activity> activities, List<CategoryGoal> goals) {
    // Sum actual duration per category (using unique non-overlapping intervals per category or sum of valid durations)
    Map<String, int> categoryActuals = {};
    for (var goal in goals) {
      categoryActuals[goal.category] = 0;
    }

    // For productivity score, sum duration minutes per category from valid activities
    for (var act in activities) {
      if (act.startMinute >= 0 && act.endMinute <= totalDayMinutes && act.startMinute < act.endMinute) {
        if (categoryActuals.containsKey(act.category)) {
          categoryActuals[act.category] = categoryActuals[act.category]! + act.durationMinutes;
        }
      }
    }

    double totalPoints = 0.0;
    for (var goal in goals) {
      int actual = categoryActuals[goal.category] ?? 0;
      double completion = actual / goal.targetDurationMinutes;
      if (completion > 1.0) completion = 1.0;
      double points = goal.weight * completion;
      totalPoints += points;
    }

    return totalPoints;
  }

  static String formatHoursMinutes(int minutes) {
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return '$hours hrs $mins mins';
    } else if (hours > 0) {
      return '$hours hrs';
    } else {
      return '$mins mins';
    }
  }

  static String _formatTime(int minutes) {
    int h = minutes ~/ 60;
    int m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

extension on List<String> {
  void pushIfNotNull(String? val) {
    if (val != null) add(val);
  }
}
