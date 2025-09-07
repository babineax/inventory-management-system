import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../screens/inventory_list_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/stock_movements_screen.dart';
import '../screens/predictions_screen.dart';
import '../screens/profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, UserModel? currentUser});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  AppUser? currentUser;
  bool isLoading = true;

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

  // keep your private helper
  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // **public** method other widgets can call
  void selectTab(int index) => _onTabSelected(index);

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

  // Updated navigation items with shorter labels
  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Items'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Stock'),
    BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Predict'),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getFirstName(currentUser?.displayName ?? 'User'),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        currentUser?.isAdmin == true ? 'Admin' : 'Staff',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
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
        selectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white54
            : Colors.grey[600],
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).bottomNavigationBarTheme.backgroundColor
            : null,
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
    if (currentUser?.profilePhotoPath != null &&
        currentUser!.profilePhotoPath!.isNotEmpty) {
      // Handle base64 data URLs
      if (currentUser!.profilePhotoPath!.startsWith('data:image')) {
        try {
          final base64String = currentUser!.profilePhotoPath!.split(',')[1];
          final bytes = base64Decode(base64String);
          return CircleAvatar(
            radius: 16,
            backgroundColor: currentUser!.isActive
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.3),
            backgroundImage: MemoryImage(bytes),
            onBackgroundImageError: (exception, stackTrace) {
              debugPrint('Error loading app bar avatar: $exception');
            },
          );
        } catch (e) {
          debugPrint('Error decoding base64 app bar avatar: $e');
        }
      } else {
        // Handle network URLs
        return CircleAvatar(
          radius: 16,
          backgroundColor: currentUser!.isActive
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.3),
          backgroundImage: NetworkImage(currentUser!.profilePhotoPath!),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Error loading network app bar avatar: $exception');
          },
        );
      }
    }

    // Fallback to initials
    return CircleAvatar(
      radius: 16,
      backgroundColor: currentUser?.isActive == true
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.grey.withValues(alpha: 0.3),
      child: Text(
        currentUser?.displayName.isNotEmpty == true
            ? currentUser!.displayName[0].toUpperCase()
            : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
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

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'User';

    // Split by spaces and get the first word (first name)
    final nameParts = fullName.trim().split(' ');
    return nameParts.isNotEmpty && nameParts[0].isNotEmpty
        ? nameParts[0]
        : 'User';
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'StockSense';
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
