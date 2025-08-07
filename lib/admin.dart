import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventory_system/stock_list_screen.dart';

import 'login.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();

 
}

class _AdminState extends State<Admin> {

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
        title: Text("Admin"),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: Icon(
              Icons.logout,
            ),
          )
        ],
      ),
      

      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
          
            
            const SizedBox(height: 20),
            _viewStockButton(context), // New button to view stock items
          ],
        ), 
      )
    );
  }

  Future<void> logout(BuildContext context) async {
    CircularProgressIndicator();
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }
}