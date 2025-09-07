import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<double> trendData;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trendData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adjust font sizes based on card size
          double valueFontSize = constraints.maxHeight > 120 ? 20 : 16;
          double titleFontSize = constraints.maxHeight > 120 ? 12 : 10;
          double iconSize = constraints.maxHeight > 120 ? 24 : 20;
          double smallIconSize = constraints.maxHeight > 120 ? 16 : 14;

          return Padding(
            padding: EdgeInsets.all(constraints.maxHeight > 120 ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: iconSize),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: color, size: smallIconSize),
                    ),
                  ],
                ),
                if (constraints.maxHeight > 100) ...[
                  const SizedBox(height: 8),
                  // Mini visualization - only show if there's enough space
                  Flexible(child: _buildMiniChart()),
                ],
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.brightness ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: titleFontSize,
                      color: Theme.of(context).colorScheme.brightness ==
                              Brightness.dark
                          ? Colors.white70
                          : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniChart() {
    if (trendData.isEmpty || trendData.every((element) => element == 0)) {
      return Container(
        height: 30,
        alignment: Alignment.center,
        child: Text(
          'No trend data',
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
        ),
      );
    }

    return SizedBox(
      height: 30,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trendData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value);
              }).toList(),
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
              ),
            ),
          ],
          minY: trendData.reduce((a, b) => a < b ? a : b) * 0.8,
          maxY: trendData.reduce((a, b) => a > b ? a : b) * 1.2,
        ),
      ),
    );
  }
}
