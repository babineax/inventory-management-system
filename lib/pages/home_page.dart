import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventory_management_system/auth.dart';
import 'package:flutter/material.dart';
import 'package:inventory_management_system/screens/stock_list_screen.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _title() {
    return const Text('Firebase Auth');
  }

  Widget _userUid() {
    return Text(user?.email ?? 'user email');
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Sign Out'),
    );
  }

  // Navigate to Stock List screen
  void _goToStockList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StockListScreen()),
    );
  }

  Widget _viewStockButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _goToStockList(context),
      child: const Text('View Stock Items'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ), // AppBar
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _userUid(),
            const SizedBox(height: 20),
            _signOutButton(),
            const SizedBox(height: 20),
            _viewStockButton(context), // New button to view stock items
          ],
        ), // Column
      ), // Container
    ); // Scaffold
  }
}
