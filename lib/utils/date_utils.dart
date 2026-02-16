class DateUtils {
  /// Converts days difference to human-readable time format
  /// Examples: "2 days ago", "yesterday", "in 1 week", "in 3 weeks", "2 months ago"
  static String formatDaysDifference(int days) {
    final absDays = days.abs();

    if (days == 0) {
      return 'today';
    } else if (days == 1) {
      return 'tomorrow';
    } else if (days == -1) {
      return 'yesterday';
    } else if (days > 0) {
      // Future dates
      if (absDays <= 6) {
        return 'in $absDays day${absDays == 1 ? '' : 's'}';
      } else if (absDays <= 13) {
        return 'in 1 week';
      } else if (absDays <= 20) {
        return 'in 2 weeks';
      } else if (absDays <= 27) {
        return 'in 3 weeks';
      } else if (absDays <= 34) {
        return 'in 1 month';
      } else if (absDays <= 61) {
        return 'in 2 months';
      } else if (absDays <= 91) {
        return 'in 3 months';
      } else {
        final months = (absDays / 30).round();
        return 'in $months month${months == 1 ? '' : 's'}';
      }
    } else {
      // Past dates
      if (absDays <= 6) {
        return '$absDays day${absDays == 1 ? '' : 's'} ago';
      } else if (absDays <= 13) {
        return '1 week ago';
      } else if (absDays <= 20) {
        return '2 weeks ago';
      } else if (absDays <= 27) {
        return '3 weeks ago';
      } else if (absDays <= 34) {
        return '1 month ago';
      } else if (absDays <= 61) {
        return '2 months ago';
      } else if (absDays <= 91) {
        return '3 months ago';
      } else {
        final months = (absDays / 30).round();
        return '$months month${months == 1 ? '' : 's'} ago';
      }
    }
  }

  /// Converts days until expiry to human-readable expiry status
  static String formatExpiryStatus(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) {
      final daysAgo = daysUntilExpiry.abs();
      if (daysAgo == 1) {
        return 'Expired yesterday';
      } else {
        return 'Expired ${formatDaysDifference(daysUntilExpiry).replaceFirst(' ago', '')} ago';
      }
    } else {
      return 'Expires ${formatDaysDifference(daysUntilExpiry)}';
    }
  }
}
