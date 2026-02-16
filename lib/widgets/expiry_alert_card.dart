import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpiryAlertCard extends StatelessWidget {
  final String title;
  final int count;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ExpiryAlertCard({
    super.key,
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width to adjust padding for smaller screens
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final cardPadding = isSmallScreen ? 12.0 : 16.0;
    final iconPadding = isSmallScreen ? 8.0 : 12.0;
    final spacing = isSmallScreen ? 12.0 : 16.0;
    final titleFontSize = isSmallScreen ? 14.0 : 16.0;
    final subtitleFontSize = isSmallScreen ? 11.0 : 12.0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[800],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: subtitleFontSize,
                        color: Theme.of(context).colorScheme.brightness ==
                                Brightness.dark
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color:
                    Theme.of(context).colorScheme.brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
