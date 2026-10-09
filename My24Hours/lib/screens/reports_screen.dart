import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../database/database_helper.dart';
import '../utils/time_utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedPeriodDays = 1; // 1 (Today), 2 (Last 2 days), 7 (Last 7 days), 30 (Last 30 days)
  bool _isLoading = true;

  // Report summary data
  List<DayReportData> _dailyReports = [];
  int _totalAccountedMinutes = 0;
  int _totalUnaccountedMinutes = 0;
  double _avgAccountingPercentage = 0.0;
  double _avgProductivityScore = 0.0;
  Map<String, int> _categoryTotals = {};

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: _selectedPeriodDays - 1));
    String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    String endDateStr = DateFormat('yyyy-MM-dd').format(now);

    final allActivities = await DatabaseHelper.instance.getActivitiesForDateRange(startDateStr, endDateStr);
    final goals = await DatabaseHelper.instance.getCategoryGoals();

    // Group activities by date
    Map<String, List<Activity>> activitiesByDate = {};
    for (int i = 0; i < _selectedPeriodDays; i++) {
      DateTime d = startDate.add(Duration(days: i));
      String dStr = DateFormat('yyyy-MM-dd').format(d);
      activitiesByDate[dStr] = [];
    }

    for (var act in allActivities) {
      if (activitiesByDate.containsKey(act.date)) {
        activitiesByDate[act.date]!.add(act);
      }
    }

    List<DayReportData> dailyList = [];
    int cumulativeAccounted = 0;
    int cumulativeUnaccounted = 0;
    double sumAccountingPct = 0.0;
    double sumProductivityScore = 0.0;
    Map<String, int> catTotals = {};

    activitiesByDate.forEach((dateStr, acts) {
      bool hasRecords = acts.isNotEmpty;
      var timeRes = TimeUtils.calculateTimeAccounting(acts);
      double prodScore = TimeUtils.calculateProductivityScore(acts, goals);

      cumulativeAccounted += timeRes.accountedMinutes;
      cumulativeUnaccounted += timeRes.remainingMinutes;
      sumAccountingPct += timeRes.accountingPercentage;
      sumProductivityScore += prodScore;

      // Status determination
      String status = 'Complete';
      if (!hasRecords) {
        status = 'No Records';
      } else if (timeRes.accountedMinutes < 1440) {
        status = 'Incomplete Day (${timeRes.accountingPercentage.toStringAsFixed(0)}%)';
      }

      // Category totals
      for (var act in timeRes.validActivities) {
        catTotals[act.category] = (catTotals[act.category] ?? 0) + act.durationMinutes;
      }

      dailyList.add(DayReportData(
        dateStr: dateStr,
        hasRecords: hasRecords,
        accountedMinutes: timeRes.accountedMinutes,
        unaccountedMinutes: timeRes.remainingMinutes,
        accountingPercentage: timeRes.accountingPercentage,
        productivityScore: prodScore,
        status: status,
      ));
    });

    // Sort descending by date
    dailyList.sort((a, b) => b.dateStr.compareTo(a.dateStr));

    setState(() {
      _dailyReports = dailyList;
      _totalAccountedMinutes = cumulativeAccounted;
      _totalUnaccountedMinutes = cumulativeUnaccounted;
      _avgAccountingPercentage = sumAccountingPct / _selectedPeriodDays;
      _avgProductivityScore = sumProductivityScore / _selectedPeriodDays;
      _categoryTotals = catTotals;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Period Reports'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Period Selector Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodChip(1, 'Today (1 Day)'),
                      const SizedBox(width: 8),
                      _buildPeriodChip(2, 'Last 2 Days'),
                      const SizedBox(width: 8),
                      _buildPeriodChip(7, 'Last 7 Days'),
                      const SizedBox(width: 8),
                      _buildPeriodChip(30, 'Last 30 Days'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cumulative & Average Summary Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary for $_selectedPeriodDays ${_selectedPeriodDays == 1 ? 'Day' : 'Days'}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryColumn('Total Accounted', TimeUtils.formatHoursMinutes(_totalAccountedMinutes)),
                            _buildSummaryColumn('Total Unaccounted', TimeUtils.formatHoursMinutes(_totalUnaccountedMinutes)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryColumn('Avg Daily Accounting', '${_avgAccountingPercentage.toStringAsFixed(1)}%'),
                            _buildSummaryColumn('Avg Productivity Score', '${_avgProductivityScore.toStringAsFixed(1)} / 100'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Totals Card (Coding, Quran, English, etc.)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category Totals',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        if (_categoryTotals.isEmpty)
                          const Text('No category activity records in this period.')
                        else
                          ..._categoryTotals.entries.map((entry) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text(TimeUtils.formatHoursMinutes(entry.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Daily Breakdown List
                const Text(
                  'Daily Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ..._dailyReports.map((day) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(day.dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Accounting: ${day.accountingPercentage.toStringAsFixed(1)}% • Score: ${day.productivityScore.toStringAsFixed(1)} pts\nStatus: ${day.status}'),
                        isThreeLine: true,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: day.hasRecords ? (day.accountingPercentage >= 99 ? Colors.green.shade100 : Colors.orange.shade100) : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            day.hasRecords ? '${day.accountingPercentage.toStringAsFixed(0)}%' : 'No Rec',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: day.hasRecords ? (day.accountingPercentage >= 99 ? Colors.green.shade800 : Colors.orange.shade800) : Colors.red.shade800,
                            ),
                          ),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }

  Widget _buildPeriodChip(int days, String label) {
    bool isSelected = _selectedPeriodDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriodDays = days;
          });
          _generateReport();
        }
      },
    );
  }

  Widget _buildSummaryColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class DayReportData {
  final String dateStr;
  final bool hasRecords;
  final int accountedMinutes;
  final int unaccountedMinutes;
  final double accountingPercentage;
  final double productivityScore;
  final String status;

  DayReportData({
    required this.dateStr,
    required this.hasRecords,
    required this.accountedMinutes,
    required this.unaccountedMinutes,
    required this.accountingPercentage,
    required this.productivityScore,
    required this.status,
  });
}
