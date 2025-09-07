import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/user_model.dart';
import '../models/inventory_item.dart';
import '../config/notification_config.dart';
import 'auth_service.dart';
import 'inventory_service.dart';

class NotificationService {
  // Initialize notification service
  static Future<void> initialize() async {
    debugPrint('NotificationService initialized');
    // Start periodic checks for expiry and stock alerts
    _startPeriodicChecks();
  }

  // Start periodic checks for notifications
  static void _startPeriodicChecks() {
    // Check every hour for expiry and stock alerts
    Future.delayed(const Duration(hours: 1), () {
      _checkExpiryAlerts();
      _checkStockAlerts();
      _startPeriodicChecks(); // Recursive call to continue checking
    });
  }

  // Send email notification with enhanced authentication and professional formatting
  static Future<bool> sendEmailNotification({
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    bool isHtml = true,
    List<int>? pdfAttachment,
    String? attachmentName,
  }) async {
    try {
      // Use OAuth2 for better Gmail authentication
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        port: 587,
        ssl: false,
        allowInsecure: false,
        username: NotificationConfig.senderEmail,
        password: NotificationConfig.senderPassword,
      );

      final message = Message()
        ..from = Address(
            NotificationConfig.senderEmail, NotificationConfig.senderName)
        ..recipients.add(Address(recipientEmail, recipientName))
        ..subject = '[StockSense] $subject'
        ..text = isHtml ? null : body
        ..html = isHtml ? _enhanceEmailWithBranding(body) : null;

      // Add PDF attachment if provided
      if (pdfAttachment != null && attachmentName != null) {
        try {
          // Create a temporary file for the attachment
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/$attachmentName');
          await tempFile.writeAsBytes(pdfAttachment);

          message.attachments.add(FileAttachment(tempFile));
        } catch (e) {
          debugPrint('Error adding PDF attachment: $e');
        }
      }

      final sendReport = await send(message, smtpServer);
      debugPrint('Email sent successfully: ${sendReport.toString()}');
      return true;
    } catch (e) {
      debugPrint('Failed to send email: $e');
      return false;
    }
  }

  // Enhance email with professional branding
  static String _enhanceEmailWithBranding(String originalBody) {
    return '''
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>StockSense Notification</title>
      </head>
      <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8f9fa;">
        <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
          <!-- Header with Company Branding -->
          <div style="background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); color: white; padding: 30px 20px; text-align: center;">
            <div style="display: inline-block; width: 80px; height: 80px; background-color: white; border-radius: 50%; margin-bottom: 15px; line-height: 80px; font-size: 32px; font-weight: bold; color: #1e3c72;">
              SS
            </div>
            <h1 style="margin: 0; font-size: 28px; font-weight: bold;">StockSense</h1>
            <p style="margin: 5px 0 0 0; font-size: 16px; opacity: 0.9;">Inventory Management System</p>
          </div>
          
          <!-- Main Content -->
          <div style="padding: 30px 20px;">
            $originalBody
          </div>
          
          <!-- Footer -->
          <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #e9ecef;">
            <p style="margin: 0; font-size: 14px; color: #6c757d;">
              <strong>StockSense Inventory Management System</strong><br>
              Professional Inventory Solutions for Modern Businesses
            </p>
            <p style="margin: 10px 0 0 0; font-size: 12px; color: #adb5bd;">
              This is an automated notification. Please do not reply to this email.<br>
              © ${DateTime.now().year} StockSense. All rights reserved.
            </p>
          </div>
        </div>
      </body>
      </html>
    ''';
  }

  // Send SMS notification
  static Future<bool> sendSMSNotification({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Format phone number (ensure it starts with +)
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+$formattedPhone';
      }

      final url = Uri.parse(
          '${NotificationConfig.twilioApiUrl}/${NotificationConfig.twilioAccountSid}/Messages.json');

      final response = await http.post(
        url,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${NotificationConfig.twilioAccountSid}:${NotificationConfig.twilioAuthToken}'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': NotificationConfig.twilioPhoneNumber,
          'To': formattedPhone,
          'Body': message,
        },
      );

      if (response.statusCode == 201) {
        debugPrint('SMS sent successfully to $formattedPhone');
        return true;
      } else {
        debugPrint(
            'Failed to send SMS: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Failed to send SMS: $e');
      return false;
    }
  }

  // Send expiry alert notification
  static Future<void> sendExpiryAlert({
    required AppUser user,
    required InventoryItem item,
    required int daysUntilExpiry,
  }) async {
    if (!user.expiryAlertsEnabled) return;

    final String alertType = daysUntilExpiry <= 0 ? 'EXPIRED' : 'EXPIRING SOON';
    final String timeText = daysUntilExpiry <= 0
        ? 'has expired'
        : 'expires in $daysUntilExpiry day${daysUntilExpiry == 1 ? '' : 's'}';

    // Email notification
    if (user.emailNotificationsEnabled) {
      final emailSubject = '🚨 $alertType: ${item.name}';
      final emailBody = '''
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0;">
              <h1 style="margin: 0; font-size: 24px;">⚠️ Inventory Alert</h1>
              <p style="margin: 5px 0 0 0; opacity: 0.9;">StockSense Notification System</p>
            </div>
            
            <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; border: 1px solid #e9ecef;">
              <h2 style="color: ${daysUntilExpiry <= 0 ? '#dc3545' : '#fd7e14'}; margin-top: 0;">
                ${daysUntilExpiry <= 0 ? '🔴 ITEM EXPIRED' : '🟠 ITEM EXPIRING SOON'}
              </h2>
              
              <div style="background: white; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid ${daysUntilExpiry <= 0 ? '#dc3545' : '#fd7e14'};">
                <h3 style="margin: 0 0 10px 0; color: #495057;">${item.name}</h3>
                <p style="margin: 5px 0;"><strong>Category:</strong> ${item.category}</p>
                <p style="margin: 5px 0;"><strong>Quantity:</strong> ${item.quantity} units</p>
                <p style="margin: 5px 0;"><strong>Supplier:</strong> ${item.supplier}</p>
                <p style="margin: 5px 0;"><strong>Status:</strong> <span style="color: ${daysUntilExpiry <= 0 ? '#dc3545' : '#fd7e14'}; font-weight: bold;">This item $timeText</span></p>
              </div>
              
              <div style="background: #e3f2fd; padding: 15px; border-radius: 8px; margin: 15px 0;">
                <h4 style="margin: 0 0 10px 0; color: #1976d2;">📋 Recommended Actions:</h4>
                <ul style="margin: 0; padding-left: 20px;">
                  ${daysUntilExpiry <= 0 ? '<li>Remove expired items from inventory immediately</li><li>Check for similar items that may also be expired</li><li>Review storage conditions to prevent future expiry</li>' : '<li>Use or sell this item as soon as possible</li><li>Consider offering discounts to move inventory</li><li>Check other items with similar expiry dates</li>'}
                </ul>
              </div>
              
              <div style="text-align: center; margin-top: 20px;">
                <p style="color: #6c757d; font-size: 14px;">
                  This is an automated notification from StockSense.<br>
                  To manage your notification preferences, please log into the app.
                </p>
              </div>
            </div>
          </div>
        </body>
        </html>
      ''';

      await sendEmailNotification(
        recipientEmail: user.email,
        recipientName: user.displayName,
        subject: emailSubject,
        body: emailBody,
      );
    }

    // SMS notification
    if (user.smsNotificationsEnabled && user.phone.isNotEmpty) {
      final smsMessage = '''
🚨 StockSense Alert: ${item.name} $timeText!

📦 Item: ${item.name}
📂 Category: ${item.category}
📊 Quantity: ${item.quantity} units
⏰ Status: $alertType

${daysUntilExpiry <= 0 ? 'Remove expired items immediately!' : 'Take action soon to prevent waste.'}

- StockSense Team
      '''
          .trim();

      await sendSMSNotification(
        phoneNumber: user.phone,
        message: smsMessage,
      );
    }
  }

  // Send stock alert notification
  static Future<void> sendStockAlert({
    required AppUser user,
    required InventoryItem item,
  }) async {
    if (!user.stockAlertsEnabled) return;

    // Email notification
    if (user.emailNotificationsEnabled) {
      final emailSubject = '📦 Low Stock Alert: ${item.name}';
      final emailBody = '''
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%); color: #8b4513; padding: 20px; border-radius: 10px 10px 0 0;">
              <h1 style="margin: 0; font-size: 24px;">📦 Stock Alert</h1>
              <p style="margin: 5px 0 0 0; opacity: 0.8;">StockSense Notification System</p>
            </div>
            
            <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; border: 1px solid #e9ecef;">
              <h2 style="color: #fd7e14; margin-top: 0;">🟠 LOW STOCK WARNING</h2>
              
              <div style="background: white; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #fd7e14;">
                <h3 style="margin: 0 0 10px 0; color: #495057;">${item.name}</h3>
                <p style="margin: 5px 0;"><strong>Category:</strong> ${item.category}</p>
                <p style="margin: 5px 0;"><strong>Current Stock:</strong> <span style="color: #dc3545; font-weight: bold;">${item.quantity} units</span></p>
                <p style="margin: 5px 0;"><strong>Reorder Level:</strong> ${item.reorderLevel} units</p>
                <p style="margin: 5px 0;"><strong>Supplier:</strong> ${item.supplier}</p>
                <p style="margin: 5px 0;"><strong>Unit Price:</strong> \$${item.unitPrice.toStringAsFixed(2)}</p>
              </div>
              
              <div style="background: #fff3cd; padding: 15px; border-radius: 8px; margin: 15px 0; border: 1px solid #ffeaa7;">
                <h4 style="margin: 0 0 10px 0; color: #856404;">📋 Recommended Actions:</h4>
                <ul style="margin: 0; padding-left: 20px; color: #856404;">
                  <li>Contact supplier: ${item.supplier}</li>
                  <li>Place reorder for this item immediately</li>
                  <li>Consider increasing reorder level if this happens frequently</li>
                  <li>Check for alternative suppliers if needed</li>
                </ul>
              </div>
              
              <div style="text-align: center; margin-top: 20px;">
                <p style="color: #6c757d; font-size: 14px;">
                  This is an automated notification from StockSense.<br>
                  To manage your notification preferences, please log into the app.
                </p>
              </div>
            </div>
          </div>
        </body>
        </html>
      ''';

      await sendEmailNotification(
        recipientEmail: user.email,
        recipientName: user.displayName,
        subject: emailSubject,
        body: emailBody,
      );
    }

    // SMS notification
    if (user.smsNotificationsEnabled && user.phone.isNotEmpty) {
      final smsMessage = '''
📦 StockSense Alert: Low Stock!

📦 Item: ${item.name}
📂 Category: ${item.category}
📊 Current: ${item.quantity} units
⚠️ Reorder Level: ${item.reorderLevel} units
🏪 Supplier: ${item.supplier}

Action needed: Reorder immediately!

- StockSense Team
      '''
          .trim();

      await sendSMSNotification(
        phoneNumber: user.phone,
        message: smsMessage,
      );
    }
  }

  // Send prediction alert notification
  static Future<void> sendPredictionAlert({
    required AppUser user,
    required String itemName,
    required String predictionType,
    required String predictionMessage,
    required Map<String, dynamic> predictionData,
  }) async {
    if (!user.predictionAlertsEnabled) return;

    // Email notification
    if (user.emailNotificationsEnabled) {
      final emailSubject = '🔮 Stock Prediction Alert: $itemName';
      final emailBody = '''
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
          <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0;">
              <h1 style="margin: 0; font-size: 24px;">🔮 AI Prediction Alert</h1>
              <p style="margin: 5px 0 0 0; opacity: 0.9;">StockSense Intelligence System</p>
            </div>
            
            <div style="background: #f8f9fa; padding: 20px; border-radius: 0 0 10px 10px; border: 1px solid #e9ecef;">
              <h2 style="color: #6f42c1; margin-top: 0;">📊 $predictionType Prediction</h2>
              
              <div style="background: white; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #6f42c1;">
                <h3 style="margin: 0 0 10px 0; color: #495057;">$itemName</h3>
                <p style="margin: 10px 0; font-size: 16px; color: #495057;">$predictionMessage</p>
                
                <div style="background: #f8f9fa; padding: 10px; border-radius: 6px; margin: 10px 0;">
                  <h4 style="margin: 0 0 8px 0; color: #6f42c1;">📈 Prediction Details:</h4>
                  ${predictionData.entries.map((entry) => '<p style="margin: 3px 0;"><strong>${entry.key}:</strong> ${entry.value}</p>').join('')}
                </div>
              </div>
              
              <div style="background: #e8f4fd; padding: 15px; border-radius: 8px; margin: 15px 0;">
                <h4 style="margin: 0 0 10px 0; color: #0c5460;">💡 AI Recommendations:</h4>
                <ul style="margin: 0; padding-left: 20px; color: #0c5460;">
                  <li>Review current stock levels and adjust accordingly</li>
                  <li>Consider seasonal trends and market conditions</li>
                  <li>Plan procurement based on predicted demand</li>
                  <li>Monitor actual vs predicted performance</li>
                </ul>
              </div>
              
              <div style="text-align: center; margin-top: 20px;">
                <p style="color: #6c757d; font-size: 14px;">
                  This prediction is generated by StockSense AI.<br>
                  Accuracy improves with more historical data.
                </p>
              </div>
            </div>
          </div>
        </body>
        </html>
      ''';

      await sendEmailNotification(
        recipientEmail: user.email,
        recipientName: user.displayName,
        subject: emailSubject,
        body: emailBody,
      );
    }

    // SMS notification
    if (user.smsNotificationsEnabled && user.phone.isNotEmpty) {
      final smsMessage = '''
🔮 StockSense AI Alert: $predictionType

📦 Item: $itemName
📊 Prediction: $predictionMessage

Key insights:
${predictionData.entries.take(3).map((e) => '• ${e.key}: ${e.value}').join('\n')}

Review your inventory strategy!

- StockSense AI
      '''
          .trim();

      await sendSMSNotification(
        phoneNumber: user.phone,
        message: smsMessage,
      );
    }
  }

  // Check for expiry alerts
  static Future<void> _checkExpiryAlerts() async {
    try {
      final items = await InventoryService.getInventoryItems();
      final users = await AuthService.getAllUsers();
      final now = DateTime.now();

      for (final item in items) {
        if (item.isPerishable && item.expiryDate != null) {
          final daysUntilExpiry = item.expiryDate!.difference(now).inDays;

          // Send alerts for items expiring in 7 days, 3 days, 1 day, or already expired
          if (daysUntilExpiry <= 7) {
            for (final user in users) {
              if (user.isActive && user.expiryAlertsEnabled) {
                await sendExpiryAlert(
                  user: user,
                  item: item,
                  daysUntilExpiry: daysUntilExpiry,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking expiry alerts: $e');
    }
  }

  // Check for stock alerts
  static Future<void> _checkStockAlerts() async {
    try {
      final items = await InventoryService.getInventoryItems();
      final users = await AuthService.getAllUsers();

      for (final item in items) {
        if (item.quantity <= item.reorderLevel) {
          for (final user in users) {
            if (user.isActive && user.stockAlertsEnabled) {
              await sendStockAlert(
                user: user,
                item: item,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking stock alerts: $e');
    }
  }

  // Manual trigger for testing notifications
  static Future<void> testNotifications() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return;

      // Test email
      if (currentUser.emailNotificationsEnabled) {
        await sendEmailNotification(
          recipientEmail: currentUser.email,
          recipientName: currentUser.displayName,
          subject: '✅ StockSense Test Notification',
          body: '''
            <html>
            <body style="font-family: Arial, sans-serif;">
              <h2>🎉 Test Notification Successful!</h2>
              <p>This is a test email from StockSense to verify your notification settings.</p>
              <p><strong>User:</strong> ${currentUser.displayName}</p>
              <p><strong>Email:</strong> ${currentUser.email}</p>
              <p><strong>Time:</strong> ${DateTime.now().toString()}</p>
              <p>If you received this email, your email notifications are working correctly!</p>
            </body>
            </html>
          ''',
        );
      }

      // Test SMS
      if (currentUser.smsNotificationsEnabled && currentUser.phone.isNotEmpty) {
        await sendSMSNotification(
          phoneNumber: currentUser.phone,
          message: '''
✅ StockSense Test SMS

Hello ${currentUser.displayName}!

This is a test message to verify your SMS notifications are working correctly.

Time: ${DateTime.now().toString().substring(0, 19)}

- StockSense Team
          '''
              .trim(),
        );
      }

      debugPrint('Test notifications sent successfully');
    } catch (e) {
      debugPrint('Error sending test notifications: $e');
    }
  }

  // Send welcome notification to new users
  static Future<void> sendWelcomeNotification(AppUser user) async {
    if (!user.emailNotificationsEnabled) return;

    final emailSubject = '🎉 Welcome to StockSense!';
    final emailBody = '''
      <html>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
            <h1 style="margin: 0; font-size: 28px;">🎉 Welcome to StockSense!</h1>
            <p style="margin: 10px 0 0 0; opacity: 0.9; font-size: 18px;">Smart Inventory Management System</p>
          </div>
          
          <div style="background: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px; border: 1px solid #e9ecef;">
            <h2 style="color: #495057; margin-top: 0;">Hello ${user.displayName}! 👋</h2>
            
            <p style="font-size: 16px; margin: 15px 0;">
              Thank you for joining StockSense! Your account has been successfully created and you're ready to start managing your inventory like a pro.
            </p>
            
            <div style="background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #28a745;">
              <h3 style="margin: 0 0 15px 0; color: #28a745;">🚀 What you can do with StockSense:</h3>
              <ul style="margin: 0; padding-left: 20px;">
                <li>📦 Track inventory in real-time</li>
                <li>📊 Get AI-powered stock predictions</li>
                <li>⚠️ Receive expiry and low stock alerts</li>
                <li>📈 View detailed analytics and reports</li>
                <li>👥 Manage team access (Admin users)</li>
                <li>📱 Access from any device</li>
              </ul>
            </div>
            
            <div style="background: #e3f2fd; padding: 20px; border-radius: 8px; margin: 20px 0;">
              <h3 style="margin: 0 0 15px 0; color: #1976d2;">🔔 Notification Settings</h3>
              <p style="margin: 0;">
                You'll receive notifications for important events like expiring items and low stock levels. 
                You can customize these settings anytime in your profile.
              </p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
              <p style="font-size: 18px; color: #495057; margin: 0;">
                Ready to get started? Log in to your dashboard and explore all the features!
              </p>
            </div>
            
            <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6;">
              <p style="color: #6c757d; font-size: 14px; margin: 0;">
                Need help? Contact our support team or check out our documentation.<br>
                Welcome aboard! 🎊
              </p>
            </div>
          </div>
        </div>
      </body>
      </html>
    ''';

    await sendEmailNotification(
      recipientEmail: user.email,
      recipientName: user.displayName,
      subject: emailSubject,
      body: emailBody,
    );
  }
}
