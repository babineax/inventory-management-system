import 'package:flutter/material.dart';

class InventorySearchScreen extends StatefulWidget {
  const InventorySearchScreen({Key? key}) : super(key: key);

  @override
  State<InventorySearchScreen> createState() => _InventorySearchScreenState();
}

class _InventorySearchScreenState extends State<InventorySearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> mockItems = [
    {'name': 'Printer', 'category': 'Office', 'stock': 5},
    {'name': 'Keyboard', 'category': 'Electronics', 'stock': 12},
    {'name': 'Paper A4', 'category': 'Stationery', 'stock': 40},
    {'name': 'Chair', 'category': 'Furniture', 'stock': 8},
  ];

  List<Map<String, dynamic>> filteredItems = [];

  @override
  void initState() {
    super.initState();
    filteredItems = mockItems;
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        filteredItems = mockItems.where((item) {
          return item['name'].toLowerCase().contains(query) ||
                 item['category'].toLowerCase().contains(query);
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Search"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by item or category",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['name']),
                      subtitle: Text("Category: ${item['category']}"),
                      trailing: Text("Stock: ${item['stock']}"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
