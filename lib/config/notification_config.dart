class NotificationConfig {
  // Email configuration - Gmail App Password approach (recommended)
  static const String smtpHost =
      String.fromEnvironment('SMTP_HOST', defaultValue: 'smtp.gmail.com');
  static const int smtpPort =
      int.fromEnvironment('SMTP_PORT', defaultValue: 587);
  static const String senderEmail =
      String.fromEnvironment('SENDER_EMAIL', defaultValue: 'email-address');
  static const String senderPassword =
      String.fromEnvironment('SENDER_PASSWORD', defaultValue: 'app-password');
  static const String senderName = String.fromEnvironment('SENDER_NAME',
      defaultValue: 'StockSense Inventory System');

  // SMS configuration (Twilio)
  // static const String twilioAccountSid = String.fromEnvironment(
  //     'TWILIO_ACCOUNT_SID',
  //     defaultValue: 'twilio-account-sid');
  // static const String twilioAuthToken = String.fromEnvironment(
  //     'TWILIO_AUTH_TOKEN',
  //     defaultValue: 'your-twilio-auth-token');
  // static const String twilioPhoneNumber = String.fromEnvironment(
  //     'TWILIO_PHONE_NUMBER',
  //     defaultValue: '+1234567890');
  // static const String twilioApiUrl =
  //     'https://api.twilio.com/2010-04-01/Accounts';

  // Validation methods
  static bool get isEmailConfigured {
    return senderEmail.contains('@gmail.com') &&
        senderEmail != 'email-address' &&
        senderPassword.length == 16 && // Gmail App Passwords are 16 characters
        senderPassword != 'app-password' &&
        !senderPassword.contains(' ') && // No spaces in app passwords
        senderPassword.contains(RegExp(r'^[a-zA-Z0-9]{16}$'));
  }

  // static bool get isSmsConfigured {
  //   return twilioAccountSid != 'twilio-account-sid' &&
  //       twilioAuthToken != 'twilio-auth-token' &&
  //       twilioPhoneNumber != '+1234567890' &&
  //       twilioPhoneNumber.startsWith('+');
  // }

  // Configuration status
  static String get emailConfigStatus {
    if (!senderEmail.contains('@gmail.com')) {
      return 'Invalid email address. Must be a Gmail address.';
    }
    if (senderPassword.length != 16) {
      return 'Invalid App Password. Gmail App Passwords are 16 characters long.';
    }
    if (senderPassword.contains(' ')) {
      return 'Invalid App Password. App Passwords contain no spaces.';
    }
    if (!senderPassword.contains(RegExp(
        r'^[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}$'))) {
      return 'Invalid App Password format. Should be XXXX-XXXX-XXXX-XXXX.';
    }
    return 'Email configuration is valid.';
  }
}
