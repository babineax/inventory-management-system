# Gmail Integration Setup Guide

## Overview
StockSense uses Gmail App Passwords for secure email notifications. This is the recommended approach by Google for third-party applications.

## Prerequisites
1. **Gmail Account**: You need a valid Gmail account
2. **2-Factor Authentication**: Must be enabled on your Gmail account
3. **App Password**: Generate a specific password for StockSense

## Step-by-Step Setup

### Step 1: Enable 2-Factor Authentication
1. Go to your [Gmail Account Settings](https://myaccount.google.com/)
2. Navigate to **Security** → **2-Step Verification**
3. Enable 2-Step Verification if not already enabled
4. Complete the verification process

### Step 2: Generate App Password
1. After enabling 2FA, go to **Security** → **App passwords**
2. Select **"Mail"** as the app type
3. Select **"Other (custom name)"** as the device
4. Enter **"StockSense App"** as the custom name
5. Click **Generate**
6. **Copy the 16-character password** (format: XXXX-XXXX-XXXX-XXXX)

### Step 3: Configure Environment Variables

#### For Development (Flutter Run)
```bash
flutter run --dart-define=SENDER_EMAIL=your-gmail@gmail.com --dart-define=SENDER_PASSWORD=abcd-efgh-ijkl-mnop
```

#### For Production Build
Create/update your environment configuration:
```bash
# Add to your build script or CI/CD
export SENDER_EMAIL=your-gmail@gmail.com
export SENDER_PASSWORD=abcd-efgh-ijkl-mnop
```

#### Alternative: Update Default Values
You can also update the default values in `lib/config/notification_config.dart`:
```dart
static const String senderEmail = String.fromEnvironment('SENDER_EMAIL',
    defaultValue: 'your-gmail@gmail.com');
static const String senderPassword = String.fromEnvironment('SENDER_PASSWORD',
    defaultValue: 'your-app-password');
```

## Testing the Setup

### Test Gmail Connection
```dart
// Call this method to test your Gmail configuration
final result = await NotificationService.testGmailConnection();
print(result['message']); // Check if connection is successful
```

### Send Test Email
```dart
// Send a test notification to verify everything works
final result = await NotificationService.testNotifications();
print('Email sent: ${result['emailSent']}');
```

## Security Best Practices

### ✅ Do's
- Use App Passwords instead of your main Gmail password
- Store credentials as environment variables
- Test connections before going to production
- Monitor your Gmail account for suspicious activity

### ❌ Don'ts
- Hardcode credentials in source code
- Share App Passwords between applications
- Use your main Gmail password
- Disable 2FA after setup

## Troubleshooting

### Common Issues

#### "Authentication failed"
- Verify your App Password is correct (16 characters, XXXX-XXXX-XXXX-XXXX format)
- Ensure 2FA is enabled on your Gmail account
- Check that you're using the App Password, not your main password

#### "Invalid email configuration"
- Ensure email contains '@gmail.com'
- Verify App Password format and length
- Check that environment variables are set correctly

#### "Connection timeout"
- Verify internet connection
- Check Gmail SMTP settings (should use smtp.gmail.com:587)
- Ensure firewall allows SMTP connections

### Gmail SMTP Settings
- **Server**: smtp.gmail.com
- **Port**: 587 (TLS)
- **Security**: STARTTLS
- **Authentication**: App Password

## Code Implementation

The app includes:
- ✅ Proper Gmail App Password validation
- ✅ Secure SMTP configuration
- ✅ Connection testing functionality
- ✅ Professional email templates
- ✅ Error handling and logging

## Support

If you encounter issues:
1. Check the console logs for detailed error messages
2. Verify your Gmail account settings
3. Test with the built-in connection test function
4. Ensure all environment variables are set correctly

## Security Notes

- App Passwords are specific to each application
- You can revoke App Passwords anytime from your Google Account
- Changing your main Gmail password doesn't affect App Passwords
- Google may require re-authentication periodically