import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  AppUser? currentUser;
  bool _isLoading = true;
  bool _isSaving = false;

  // Local state for settings
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = true;
  bool _expiryAlertsEnabled = true;
  bool _stockAlertsEnabled = true;
  bool _predictionAlertsEnabled = true;

  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      currentUser = AuthService.currentUser;
      if (currentUser != null) {
        setState(() {
          _emailNotificationsEnabled = currentUser!.emailNotificationsEnabled;
          _smsNotificationsEnabled = currentUser!.smsNotificationsEnabled;
          _expiryAlertsEnabled = currentUser!.expiryAlertsEnabled;
          _stockAlertsEnabled = currentUser!.stockAlertsEnabled;
          _predictionAlertsEnabled = currentUser!.predictionAlertsEnabled;
          _phoneController.text = currentUser!.phone;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await AuthService.updateUserProfile(
        phone: _phoneController.text.trim(),
        emailNotificationsEnabled: _emailNotificationsEnabled,
        smsNotificationsEnabled: _smsNotificationsEnabled,
        expiryAlertsEnabled: _expiryAlertsEnabled,
        stockAlertsEnabled: _stockAlertsEnabled,
        predictionAlertsEnabled: _predictionAlertsEnabled,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _testNotifications() async {
    try {
      await NotificationService.testNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notifications sent! Check your email and SMS.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context).primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_active,
                                color: Theme.of(context).primaryColor,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Notification Preferences',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Customize how you receive alerts and notifications from StockSense.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Phone Number Section
                    _buildSectionCard(
                      title: 'Contact Information',
                      icon: Icons.phone,
                      children: [
                        Text(
                          'Phone Number for SMS Notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '+1234567890',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            helperText:
                                'Include country code (e.g., +254 for Kenya)',
                            helperStyle: GoogleFonts.poppins(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white60
                                  : Colors.grey[600],
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Notification Methods
                    _buildSectionCard(
                      title: 'Notification Methods',
                      icon: Icons.send,
                      children: [
                        _buildSwitchTile(
                          title: 'Email Notifications',
                          subtitle: 'Receive notifications via email',
                          value: _emailNotificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _emailNotificationsEnabled = value;
                            });
                          },
                          icon: Icons.email,
                        ),
                        _buildSwitchTile(
                          title: 'SMS Notifications',
                          subtitle: 'Receive notifications via text message',
                          value: _smsNotificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _smsNotificationsEnabled = value;
                            });
                          },
                          icon: Icons.sms,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Alert Types
                    _buildSectionCard(
                      title: 'Alert Types',
                      icon: Icons.warning,
                      children: [
                        _buildSwitchTile(
                          title: 'Expiry Alerts',
                          subtitle:
                              'Get notified when items are about to expire',
                          value: _expiryAlertsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _expiryAlertsEnabled = value;
                            });
                          },
                          icon: Icons.schedule,
                          iconColor: Colors.orange,
                        ),
                        _buildSwitchTile(
                          title: 'Stock Alerts',
                          subtitle: 'Get notified when stock levels are low',
                          value: _stockAlertsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _stockAlertsEnabled = value;
                            });
                          },
                          icon: Icons.inventory,
                          iconColor: Colors.red,
                        ),
                        _buildSwitchTile(
                          title: 'Prediction Alerts',
                          subtitle:
                              'Get AI-powered stock predictions and insights',
                          value: _predictionAlertsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _predictionAlertsEnabled = value;
                            });
                          },
                          icon: Icons.analytics,
                          iconColor: Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Test Notifications
                    _buildSectionCard(
                      title: 'Test Notifications',
                      icon: Icons.bug_report,
                      children: [
                        Text(
                          'Send test notifications to verify your settings are working correctly.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _testNotifications,
                            icon: const Icon(Icons.send),
                            label: Text(
                              'Send Test Notifications',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Information Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[900]!.withOpacity(0.3)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue[400]!
                              : Colors.blue[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.blue[300]
                                    : Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Important Information',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.blue[300]
                                      : Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Notifications are checked every hour\n'
                            '• Expiry alerts are sent 7, 3, and 1 day(s) before expiration\n'
                            '• Stock alerts are sent when quantity falls below reorder level\n'
                            '• SMS charges may apply based on your carrier\n'
                            '• You can change these settings anytime',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.blue[200]
                                  : Colors.blue[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            }),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]?.withOpacity(0.3)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).primaryColor)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Theme.of(context).primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
