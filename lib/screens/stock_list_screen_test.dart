import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: StockListScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class StockListScreen extends StatefulWidget {
  const StockListScreen({Key? key}) : super(key: key);

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  String searchQuery = '';

  // Mocked "Firebase" documents
  final List<Map<String, dynamic>> documents = [
    {
      'item_name': 'Ballpoint Pen',
      'item_cat': 'Writing',
      'item_desc': 'Blue ink pen',
      'item_qty': 100,
    },
    {
      'item_name': 'Notebook',
      'item_cat': 'Paper',
      'item_desc': 'A5 ruled notebook',
      'item_qty': 50,
    },
    {
      'item_name': 'Stapler',
      'item_cat': 'Accessories',
      'item_desc': 'Office stapler',
      'item_qty': 20,
    },
    {
      'item_name': 'Highlighter',
      'item_cat': 'Writing',
      'item_desc': 'Yellow marker',
      'item_qty': 35,
    },
    {
      'item_name': 'File Folder',
      'item_cat': 'Organization',
      'item_desc': 'Plastic A4 folder',
      'item_qty': 60,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredDocs = documents.where((doc) {
      final itemName = doc['item_name']?.toString().toLowerCase() ?? '';
      final itemCat = doc['item_cat']?.toString().toLowerCase() ?? '';
      return itemName.contains(searchQuery) || itemCat.contains(searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Items'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or category',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: filteredDocs.isEmpty
                ? const Center(child: Text('No stock items found.'))
                : ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data = filteredDocs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(data['item_name'] ?? 'No name'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Category: ${data['item_cat'] ?? ''}'),
                              Text('Description: ${data['item_desc'] ?? ''}'),
                              Text('Quantity: ${data['item_qty'] ?? ''}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}