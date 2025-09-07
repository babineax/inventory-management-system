import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import '../models/inventory_item.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'inventory_form_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  Barcode? result;
  AppUser? currentUser;
  MobileScannerController? controller;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    controller = MobileScannerController();
  }

  void _loadCurrentUser() {
    setState(() {
      currentUser = AuthService.currentUser;
    });

    // Listen to auth state changes
    AuthService.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          currentUser = user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is admin, if not show access denied message
    if (currentUser == null || !currentUser!.isAdmin) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Access Denied',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need admin privileges to access the QR scanner.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Scan QR/Bar Code',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (!kIsWeb)
            Expanded(
              flex: 4,
              child: MobileScanner(
                controller: controller,
                onDetect: (BarcodeCapture capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    setState(() {
                      result = barcodes.first;
                    });
                  }
                },
              ),
            )
          else
            const Expanded(
              flex: 4,
              child: Center(
                child: Text('QR Scanner is not available on web'),
              ),
            ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (result != null)
                    Column(
                      children: [
                        Text(
                          'Scanned Data',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result!.rawValue ?? 'No data',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _processScannedData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Process Scanned Data',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Scan a QR or Bar code',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processScannedData() {
    if (result != null) {
      try {
        // Try to parse the scanned data as JSON
        final Map<String, dynamic> data = json.decode(result!.rawValue!);

        // Helper functions to safely parse different data types
        int parseInt(dynamic value, [int defaultValue = 0]) {
          if (value is int) return value;
          if (value is String) return int.tryParse(value) ?? defaultValue;
          if (value is double) return value.toInt();
          return defaultValue;
        }

        double parseDouble(dynamic value, [double defaultValue = 0.0]) {
          if (value is double) return value;
          if (value is int) return value.toDouble();
          if (value is String) return double.tryParse(value) ?? defaultValue;
          return defaultValue;
        }

        bool parseBool(dynamic value, [bool defaultValue = false]) {
          if (value is bool) return value;
          if (value is String) return value.toLowerCase() == 'true';
          if (value is int) return value == 1;
          return defaultValue;
        }

        DateTime? parseDate(dynamic value) {
          if (value is DateTime) return value;
          if (value is String) return DateTime.tryParse(value);
          if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
          return null;
        }

        // Create an inventory item from the scanned data
        final InventoryItem item = InventoryItem(
          id: '', // Will be generated by Firebase
          name: data['name'] as String? ?? 'Unknown Item',
          description: data['description'] as String? ?? '',
          category: data['category'] as String? ?? 'Miscellaneous',
          quantity: parseInt(data['quantity']),
          unitPrice: parseDouble(data['unitPrice']),
          supplier: data['supplier'] as String? ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          reorderLevel: parseInt(data['reorderLevel'], 10),
          imageUrl: data['imageUrl'] as String?,
          isPerishable: parseBool(data['isPerishable']),
          expiryDate: parseDate(data['expiryDate']),
        );

        // Navigate to the inventory form screen with the scanned item
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InventoryFormScreen(
              item: item,
              isEditing: false,
            ),
          ),
        );
      } catch (e) {
        // If parsing fails, show the raw data in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Scanned Data',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to parse as JSON. Raw data:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result!.rawValue ?? 'No data',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
