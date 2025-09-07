import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final bool showAddButton;
  final VoidCallback? onAddPressed;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.showAddButton = false,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[600]
                  : Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey[600]),
          ),
          if (showAddButton) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: Text(
                'Add Item',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60
                      : Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }
}
