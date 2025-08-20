import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../screens/inventory_list_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/stock_movements_screen.dart';
import '../screens/predictions_screen.dart';
import '../screens/profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  AppUser? currentUser;
  bool isLoading = true;

  // Single source of truth for pages (avoid using instance members in field initializers)
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // Initialize pages here so we can safely pass instance members like _onTabSelected
    _pages = [
      DashboardScreen(onTabSelected: _onTabSelected),
      const InventoryListScreen(),
      const StockMovementsScreen(),
      const PredictionsScreen(),
      const ProfileScreen(),
    ];
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      // Get current user from AuthService
      currentUser = AuthService.currentUser;

      // Listen to auth state changes
      AuthService.authStateChanges.listen((user) {
        if (mounted) {
          setState(() {
            currentUser = user;
          });
        }
      });

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventory'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Movements'),
    BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Predictions'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currentUser?.displayName ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      currentUser?.isAdmin == true ? 'Administrator' : 'Staff',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                _buildAppBarAvatar(),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages, // <- use the single list
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        items: _navItems,
      ),
    );
  }

  Widget _buildAppBarAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.white.withOpacity(0.2),
      child: ClipOval(
        child: currentUser?.profilePhotoPath != null
            ? Image.network(
                currentUser!.profilePhotoPath!,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAppBarAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 32,
                    height: 32,
                    color: Colors.white.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 1,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  );
                },
              )
            : _buildDefaultAppBarAvatar(),
      ),
    );
  }

  Widget _buildDefaultAppBarAvatar() {
    final initials = _getInitials(currentUser?.displayName ?? 'User');
    return Text(
      initials,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'U';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : 'U';
    }
    return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Inventory';
      case 2:
        return 'Stock Movements';
      case 3:
        return 'Predictions';
      case 4:
        return 'Profile';
      default:
        return 'Inventory Manager';
    }
  }
}
