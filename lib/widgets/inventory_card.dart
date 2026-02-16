import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../models/inventory_item.dart';

class InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final Function(String, InventoryItem)? onActionSelected;
  final bool isAdmin;

  const InventoryCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onActionSelected,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.quantity <= item.reorderLevel;
    final isOutOfStock = item.quantity == 0;

    Color statusColor = Colors.green;
    String statusText = 'In Stock';
    IconData statusIcon = Icons.check_circle;

    if (isOutOfStock) {
      statusColor = Colors.red;
      statusText = 'Out of Stock';
      statusIcon = Icons.error;
    } else if (isLowStock) {
      statusColor = Colors.orange;
      statusText = 'Low Stock';
      statusIcon = Icons.warning;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Item image or placeholder (reduced size)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[600]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _buildItemImage(context),
                ),
              ),
              const SizedBox(width: 12),

              // Middle - Main content (expanded for better text visibility)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with name and category
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.name,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.category.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.category,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white70
                                      : Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Details row with better spacing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quantity with status
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${item.quantity} units',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Price
                            Text(
                              '\$${item.unitPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Supplier on separate line for better visibility
                        if (item.supplier.isNotEmpty)
                          Text(
                            'Supplier: ${item.supplier}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white60
                                  : Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Right side - Actions and predictions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Actions Menu
                  if (isAdmin)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (onActionSelected != null) {
                          onActionSelected!(value, item);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'adjust', child: Text('Adjust Stock')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete')),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white60
                            : Colors.grey[600],
                      ),
                    ),

                  // Removed days left display to prevent overflow
                  // This information is available on the predictions screen
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemImage(BuildContext context) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      // Handle base64 data URLs
      if (item.imageUrl!.startsWith('data:image')) {
        try {
          final base64String = item.imageUrl!.split(',')[1];
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {

              return _buildPlaceholderIcon(context);
            },
          );
        } catch (e) {

          return _buildPlaceholderIcon(context);
        }
      } else {
        // Handle network URLs
        return Image.network(
          item.imageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderIcon(context);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            );
          },
        );
      }
    }

    return _buildPlaceholderIcon(context);
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Icon(
      Icons.inventory_2,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white60
          : Colors.grey[600],
      size: 30,
    );
  }
}
