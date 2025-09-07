import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'How do I add a new inventory item?',
      answer:
          'Navigate to the Inventory tab and tap the "Add Item" button. Fill in the required information including name, description, category, quantity, and price. You can also add an image and set expiry dates for perishable items.',
    ),
    FAQItem(
      question: 'How do stock predictions work?',
      answer:
          'Our AI-powered system analyzes your inventory usage patterns, stock movements, and historical data to predict when items will run out. Predictions are categorized as High, Medium, or Low confidence based on data consistency.',
    ),
    FAQItem(
      question: 'How do I set up notifications?',
      answer:
          'Go to Profile > Settings > Notifications to configure your notification preferences. You can enable/disable email and SMS notifications for expiry alerts, stock alerts, and predictions.',
    ),
    FAQItem(
      question: 'What are reorder levels?',
      answer:
          'Reorder levels are the minimum quantity thresholds for each item. When stock falls below this level, you\'ll receive alerts to restock the item. You can set custom reorder levels when adding or editing items.',
    ),
    FAQItem(
      question: 'How do I manage user accounts?',
      answer:
          'Admin users can manage other users by going to Profile > Admin Tools > Manage Users. You can add new users, edit existing accounts, promote/demote roles, and activate/deactivate accounts.',
    ),
    FAQItem(
      question: 'Can I export my inventory data?',
      answer:
          'Yes! Admin users can access System Reports in Admin Tools to view comprehensive analytics and export data. Reports can be downloaded or shared via email/WhatsApp.',
    ),
    FAQItem(
      question: 'How do I scan QR codes or barcodes?',
      answer:
          'Use the QR/Barcode scanner available in the quick actions on the dashboard. This feature allows you to quickly add items or update quantities by scanning product codes.',
    ),
    FAQItem(
      question: 'What happens when items expire?',
      answer:
          'The system tracks expiry dates for perishable items and sends notifications 7, 3, and 1 day(s) before expiration. Expired items are highlighted in red in the expiry alerts section.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.help_center,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need Help?',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.grey[800],
                                ),
                              ),
                              Text(
                                'Find answers to common questions or contact our support team.',
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            'Contact Support',
                            Icons.support_agent,
                            Colors.blue,
                            _contactSupport,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionButton(
                            'Report Bug',
                            Icons.bug_report,
                            Colors.red,
                            _reportBug,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            'Feature Request',
                            Icons.lightbulb,
                            Colors.orange,
                            _requestFeature,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionButton(
                            'User Guide',
                            Icons.menu_book,
                            Colors.green,
                            _showUserGuide,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // FAQ Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequently Asked Questions',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._faqItems.map((faq) => _buildFAQItem(faq)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Contact Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildContactItem(
                      Icons.email,
                      'Email Support',
                      'support@stocksense.com',
                      () => _launchEmail('support@stocksense.com'),
                    ),
                    _buildContactItem(
                      Icons.phone,
                      'Phone Support',
                      '+1 (555) 123-4567',
                      () => _launchPhone('+15551234567'),
                    ),
                    _buildContactItem(
                      Icons.language,
                      'Website',
                      'www.stocksense.com',
                      () => _launchWebsite('https://www.stocksense.com'),
                    ),
                    _buildContactItem(
                      Icons.schedule,
                      'Support Hours',
                      'Mon-Fri: 9AM-6PM EST',
                      null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            faq.answer,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.grey[600],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String title,
    String value,
    VoidCallback? onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white60
              : Colors.grey[600],
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.grey[600],
            )
          : null,
      onTap: onTap,
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Contact Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How would you like to contact our support team?',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactOption(
                  'Email',
                  Icons.email,
                  Colors.blue,
                  () {
                    Navigator.pop(context);
                    _launchEmail('support@stocksense.com');
                  },
                ),
                _buildContactOption(
                  'Phone',
                  Icons.phone,
                  Colors.green,
                  () {
                    Navigator.pop(context);
                    _launchPhone('+15551234567');
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reportBug() {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Report a Bug',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Bug Summary',
                  prefixIcon: const Icon(Icons.bug_report),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Detailed Description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText:
                      'Please describe the bug, steps to reproduce, and expected behavior...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitBugReport(
                  subjectController.text, descriptionController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Submit Bug Report',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _requestFeature() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Feature Request',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Feature Title',
                  prefixIcon: const Icon(Icons.lightbulb),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Feature Description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText:
                      'Please describe the feature you would like to see...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitFeatureRequest(
                  titleController.text, descriptionController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Submit Request',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUserGuide() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserGuideScreen(),
      ),
    );
  }

  void _submitBugReport(String subject, String description) {
    final bugReport = '''
Bug Report: $subject

Description:
$description

Device Information:
- App Version: 2.3.0
- Platform: ${Theme.of(context).platform}
- Timestamp: ${DateTime.now()}

Please contact support@stocksense.com for assistance.
''';

    Share.share(bugReport, subject: 'StockSense Bug Report: $subject');
  }

  void _submitFeatureRequest(String title, String description) {
    final featureRequest = '''
Feature Request: $title

Description:
$description

Submitted by: StockSense User
Timestamp: ${DateTime.now()}

Please contact support@stocksense.com to discuss this feature.
''';

    Share.share(featureRequest, subject: 'StockSense Feature Request: $title');
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=StockSense Support Request',
    );

    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Could not launch email client. Please email $email directly.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);

    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Could not launch phone dialer. Please call $phone directly.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _launchWebsite(String url) async {
    final Uri websiteUri = Uri.parse(url);

    try {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Could not launch website. Please visit $url directly.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Guide',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGuideSection(
              context,
              'Getting Started',
              Icons.play_arrow,
              [
                'Sign in with your credentials and select your role (Staff or Admin)',
                'Explore the dashboard to see inventory overview and quick actions',
                'Navigate between tabs: Home, Items, Stock, Predictions, and Profile',
              ],
            ),
            _buildGuideSection(
              context,
              'Managing Inventory',
              Icons.inventory_2,
              [
                'Add new items using the "Add Item" button (Admin only)',
                'Set reorder levels to receive low stock alerts',
                'Upload item images for better identification',
                'Track expiry dates for perishable items',
              ],
            ),
            _buildGuideSection(
              context,
              'Stock Movements',
              Icons.history,
              [
                'View all stock movements in the Stock tab',
                'Filter movements by type, date range, or search terms',
                'Adjust stock quantities with reasons for tracking',
              ],
            ),
            _buildGuideSection(
              context,
              'Predictions & Analytics',
              Icons.analytics,
              [
                'View AI-powered stock predictions in the Predictions tab',
                'Filter predictions by confidence level or urgency',
                'Use predictions to plan restocking schedules',
              ],
            ),
            _buildGuideSection(
              context,
              'User Management (Admin)',
              Icons.admin_panel_settings,
              [
                'Access user management from Profile > Admin Tools',
                'Add new users with temporary passwords',
                'Promote/demote users between Staff and Admin roles',
                'Activate/deactivate user accounts as needed',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideSection(
      BuildContext context, String title, IconData icon, List<String> steps) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue[300]
                      : Colors.blue,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue[300]
                              : Colors.blue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          step,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
