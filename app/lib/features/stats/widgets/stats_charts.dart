part of '../stats_screen.dart';

class _BigStat extends StatelessWidget {
  const _BigStat(
      {required this.value, required this.label, this.accent = false});
  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(color: accent ? p.accentText : p.text)),
        Text(label, style: TextStyle(color: p.muted, fontSize: 13)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.description,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String description;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      height: 110,
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(color: p.muted, fontSize: 10),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _ScoreDistributionChart extends StatelessWidget {
  const _ScoreDistributionChart({required this.buckets});
  final List<ScoreBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final maxY =
        buckets.fold<int>(0, (m, b) => b.count > m ? b.count : m).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => p.surface2,
            tooltipBorder: BorderSide(color: p.line),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final bucket = buckets[groupIndex];
              return BarTooltipItem(
                '${bucket.label}점\n',
                TextStyle(color: p.text, fontWeight: FontWeight.bold, fontSize: 11),
                children: [
                  TextSpan(
                    text: '${bucket.count}곡',
                    style: TextStyle(color: p.accentText, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3 > 0 ? (maxY / 3).roundToDouble() : 1.0,
          getDrawingHorizontalLine: (value) => FlLine(
            color: p.line.withValues(alpha: 0.5),
            strokeWidth: 0.8,
            dashArray: [4, 4],
          ),
        ),
        barGroups: buckets.asMap().entries.map((e) {
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(
              toY: e.value.count.toDouble(),
              gradient: LinearGradient(
                colors: [p.accent, p.accent.withValues(alpha: 0.5)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 14,
              borderRadius: BorderRadius.circular(3),
            ),
          ]);
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= buckets.length) return const SizedBox.shrink();
                if (idx % 2 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    buckets[idx].label,
                    style: TextStyle(fontSize: 10, color: p.muted, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                if (v == 0) return const SizedBox.shrink();
                if (v % 1 != 0) return const SizedBox.shrink();
                return Text(
                  '${v.toInt()}',
                  style: TextStyle(fontSize: 9, color: p.muted),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: p.line),
          ),
        ),
      ),
    );
  }
}

class _TagBar extends StatelessWidget {
  const _TagBar({required this.tag, required this.max, required this.isKo});
  final TagCount tag;
  final int max;
  final bool isKo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fraction = max == 0 ? 0.0 : tag.count / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(tag.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: p.line,
                color: p.accent,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('${tag.count}${isKo ? '개' : ''}', style: TextStyle(color: p.muted)),
        ],
      ),
    );
  }
}

class _PreferenceBar extends StatelessWidget {
  const _PreferenceBar({required this.pref, required this.isKo});
  final TagPreference pref;
  final bool isKo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scoreString = pref.averageScore.toStringAsFixed(1);
    final countSuffix = isKo ? '${pref.count}개' : '${pref.count} items';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(pref.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pref.averageScore / 10.0,
                minHeight: 8,
                backgroundColor: p.line,
                color: p.accent,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(isKo ? '$scoreString점 ($countSuffix)' : '$scoreString ($countSuffix)',
              style: TextStyle(color: p.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.activity});
  final List<ActivityPoint> activity;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final maxY = activity
        .fold<int>(0, (m, a) => a.comparisons > m ? a.comparisons : m)
        .toDouble();
    return LineChart(
      LineChartData(
        maxY: maxY == 0 ? 1 : maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => p.surface2,
            tooltipBorder: BorderSide(color: p.line),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = activity[spot.x.toInt()].date;
                return LineTooltipItem(
                  '${date.month}월 ${date.day}일\n',
                  TextStyle(color: p.text, fontWeight: FontWeight.bold, fontSize: 11),
                  children: [
                    TextSpan(
                      text: '${spot.y.toInt()}회 비교',
                      style: TextStyle(color: p.accentText, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3 > 0 ? (maxY / 3).roundToDouble() : 1.0,
          getDrawingHorizontalLine: (value) => FlLine(
            color: p.line.withValues(alpha: 0.5),
            strokeWidth: 0.8,
            dashArray: [4, 4],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: activity.length == 1
                ? [
                    const FlSpot(0, 0),
                    FlSpot(1, activity[0].comparisons.toDouble()),
                  ]
                : activity
                    .asMap()
                    .entries
                    .map((e) =>
                        FlSpot(e.key.toDouble(), e.value.comparisons.toDouble()))
                    .toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [p.accent, p.accent.withValues(alpha: 0.7)],
            ),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3.5,
                color: p.accent,
                strokeWidth: 1.5,
                strokeColor: p.bg,
              ),
            ),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [p.accent.withValues(alpha: 0.2), p.accent.withValues(alpha: 0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= activity.length) return const SizedBox.shrink();
                if (activity.length > 5 && idx % (activity.length ~/ 3) != 0 && idx != activity.length - 1) {
                  return const SizedBox.shrink();
                }
                final date = activity[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(fontSize: 9, color: p.muted),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                if (v == 0) return const SizedBox.shrink();
                if (v % 1 != 0) return const SizedBox.shrink();
                return Text(
                  '${v.toInt()}',
                  style: TextStyle(fontSize: 9, color: p.muted),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: p.line),
          ),
        ),
      ),
    );
  }
}
