import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Summary Cards Section ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _SummaryCard(title: "Items", count: 120, icon: Icons.inventory),
                _SummaryCard(title: "Suppliers", count: 15, icon: Icons.store),
                _SummaryCard(title: "Customers", count: 42, icon: Icons.people),
              ],
            ),
            const SizedBox(height: 20),

            // --- Forecast Highlights Section ---
            const Text(
              "Forecast Highlights",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _ForecastCard(
              itemName: "Pencils",
              daysLeft: 2,
              isCritical: true,
            ),
            _ForecastCard(
              itemName: "Rulers",
              daysLeft: 5,
              isCritical: false,
            ),
            _ForecastCard(
              itemName: "Books",
              daysLeft: 1,
              isCritical: true,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Summary Card Widget ---
class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _SummaryCard({
    Key? key,
    required this.title,
    required this.count,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Colors.blueAccent),
              const SizedBox(height: 8),
              Text(
                "$count",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(title, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Forecast Card Widget ---
class _ForecastCard extends StatelessWidget {
  final String itemName;
  final int daysLeft;
  final bool isCritical;

  const _ForecastCard({
    Key? key,
    required this.itemName,
    required this.daysLeft,
    required this.isCritical,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isCritical ? Colors.red[100] : Colors.orange[100],
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          Icons.warning,
          color: isCritical ? Colors.red : Colors.orange,
        ),
        title: Text(itemName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Will run out in $daysLeft days"),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}