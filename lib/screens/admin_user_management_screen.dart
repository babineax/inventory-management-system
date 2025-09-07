import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/offline_service.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  UserRole? _selectedRoleFilter;
  bool? _selectedStatusFilter;

  // Pagination state
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMoreUsers = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 120 &&
        !_isLoadingMore &&
        !_isLoading &&
        _hasMoreUsers) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMoreUsers = true;
    });

    try {
      List<AppUser> users;
      if (OfflineService.isOnline) {
        users = await AuthService.getAllUsers();
        // Save to offline storage
        await OfflineService.saveUsersOffline(users);
      } else {
        users = await OfflineService.getUsersOffline();
      }

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
        _hasMoreUsers = users.length >= _pageSize;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMoreUsers) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Simulate loading delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // For now, we'll just show more users from the existing list
      // In a real implementation, you'd fetch the next page from the server
      final nextPageStart = (_currentPage + 1) * _pageSize;
      final nextPageEnd = nextPageStart + _pageSize;

      if (nextPageStart < _users.length) {
        final newUsers = _users.sublist(
          nextPageStart,
          nextPageEnd.clamp(0, _users.length),
        );

        setState(() {
          _currentPage++;
          _hasMoreUsers = nextPageEnd < _users.length;
          _isLoadingMore = false;
        });

        // Re-apply filters to include new users
        _filterUsers();
      } else {
        setState(() {
          _hasMoreUsers = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = user.displayName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesRole =
            _selectedRoleFilter == null || user.role == _selectedRoleFilter;
        final matchesStatus = _selectedStatusFilter == null ||
            user.isActive == _selectedStatusFilter;

        return matchesSearch && matchesRole && matchesStatus;
      }).toList();

      // Reset pagination when filters change
      _currentPage = 0;
      _hasMoreUsers = _filteredUsers.length > _pageSize;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterUsers();

    // Scroll to top when search changes
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onRoleFilterChanged(UserRole? role) {
    setState(() {
      _selectedRoleFilter = role;
    });
    _filterUsers();

    // Scroll to top when filter changes
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _onStatusFilterChanged(bool? status) {
    setState(() {
      _selectedStatusFilter = status;
    });
    _filterUsers();

    // Scroll to top when filter changes
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await _loadUsers();
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[50],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<UserRole?>(
                        initialValue: _selectedRoleFilter,
                        decoration: InputDecoration(
                          labelText: 'Filter by Role',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem<UserRole?>(
                            value: null,
                            child: Text('All Roles'),
                          ),
                          ...UserRole.values
                              .map((role) => DropdownMenuItem<UserRole?>(
                                    value: role,
                                    child: Text(role
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase()),
                                  )),
                        ],
                        onChanged: _onRoleFilterChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        initialValue: _selectedStatusFilter,
                        decoration: InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem<bool?>(
                            value: null,
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem<bool?>(
                            value: true,
                            child: Text('Active'),
                          ),
                          DropdownMenuItem<bool?>(
                            value: false,
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: _onStatusFilterChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _users.isEmpty
                                  ? 'No users found'
                                  : 'No users match your filters',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_users.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'User management functionality is coming soon',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            _filteredUsers.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _filteredUsers.length) {
                            final user = _filteredUsers[index];
                            return _buildUserCard(user);
                          } else {
                            // Loading indicator at the bottom
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? Theme.of(context)
                  .primaryColor
                  .withOpacity(0.15) // Active background
              : Colors.grey.withOpacity(0.1), // Faint background for inactive
          child: Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : 'U',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: user.isActive
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white // Active in dark mode
                      : Theme.of(context).primaryColor) // Active in light mode
                  : Colors.grey.withOpacity(0.5), // Faint inactive text
            ),
          ),
        ),
        title: Text(
          user.displayName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.role == UserRole.admin
                        ? Colors.purple.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role.toString().split('.').last.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: user.role == UserRole.admin
                          ? Colors.purple[700]
                          : Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color:
                          user.isActive ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showUserDetailsDialog(user);
                break;
              case 'edit':
                _showEditUserDialog(user);
                break;
              case 'toggle_status':
                _toggleUserStatus(user);
                break;
              case 'delete':
                _showDeleteUserDialog(user);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View Details'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit User'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: ListTile(
                leading: Icon(user.isActive ? Icons.block : Icons.check_circle),
                title: Text(user.isActive ? 'Deactivate' : 'Activate'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete User', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showUserDetailsDialog(user),
      ),
    );
  }

  Future<void> _showUserDetailsDialog(AppUser user) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'User Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Name', user.displayName),
              _buildDetailRow('Email', user.email),
              _buildDetailRow(
                  'Phone', user.phone.isNotEmpty ? user.phone : 'Not provided'),
              _buildDetailRow(
                  'Role', user.role.toString().split('.').last.toUpperCase()),
              _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow(
                  'Created', DateFormat('MMM dd, yyyy').format(user.createdAt)),
              _buildDetailRow('Last Login',
                  DateFormat('MMM dd, yyyy • h:mm a').format(user.lastLoginAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditUserDialog(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Edit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditUserDialog(AppUser user) async {
    final nameController = TextEditingController(text: user.displayName);
    final phoneController = TextEditingController(text: user.phone);
    UserRole selectedRole = user.role;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Edit User',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: const Icon(Icons.admin_panel_settings),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: UserRole.values
                      .map((role) => DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(
                                role.toString().split('.').last.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedRole = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active Status'),
                  subtitle:
                      Text(isActive ? 'User is active' : 'User is inactive'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() {
                      isActive = value;
                    });
                  },
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
              onPressed: () async {
                Navigator.pop(context);
                await _updateUser(user, nameController.text,
                    phoneController.text, selectedRole, isActive);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Save Changes',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddUserDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.staff;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Add New User',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      prefixIcon: const Icon(Icons.admin_panel_settings),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: UserRole.values
                        .map((role) => DropdownMenuItem<UserRole>(
                              value: role,
                              child: Text(role
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    emailController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  Navigator.pop(context);
                  await _createUser(
                    nameController.text,
                    emailController.text,
                    phoneController.text,
                    passwordController.text,
                    selectedRole,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Create User',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUser(AppUser user, String name, String phone,
      UserRole role, bool isActive) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      if (OfflineService.isOnline) {
        await AuthService.updateUserByAdmin(
          userId: user.id,
          displayName: name,
          phone: phone,
          role: role,
          isActive: isActive,
        );
      } else {
        // Add to pending changes for offline sync
        await OfflineService.addPendingChange({
          'type': 'update_user',
          'data': user
              .copyWith(
                displayName: name,
                phone: phone,
                role: role,
                isActive: isActive,
              )
              .toJson(),
        });
      }

      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'User updated successfully${OfflineService.isOnline ? '' : ' (will sync when online)'}'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload users
      await _loadUsers();
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createUser(String name, String email, String phone,
      String password, UserRole role) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      if (OfflineService.isOnline) {
        await AuthService.createUserByAdmin(
          email: email,
          password: password,
          displayName: name,
          phone: phone,
          role: role,
        );
      } else {
        // For offline mode, we can't create Firebase Auth users
        // So we'll show an error message
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User creation requires internet connection'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'User created successfully! A password reset email has been sent to $email'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      // Show additional info dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'User Created Successfully',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The user account has been created with the following details:',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text('• Name: $name', style: GoogleFonts.poppins(fontSize: 12)),
              Text('• Email: $email', style: GoogleFonts.poppins(fontSize: 12)),
              Text('• Role: ${role.toString().split('.').last.toUpperCase()}',
                  style: GoogleFonts.poppins(fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Important:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A password reset email has been sent to $email. The user should check their email and set a new password before logging in.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      );

      // Reload users
      await _loadUsers();
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleUserStatus(AppUser user) async {
    try {
      if (OfflineService.isOnline) {
        await AuthService.toggleUserStatus(user.id, !user.isActive);
      } else {
        // Add to pending changes for offline sync
        await OfflineService.addPendingChange({
          'type': 'update_user',
          'data': user.copyWith(isActive: !user.isActive).toJson(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'User ${!user.isActive ? 'activated' : 'deactivated'} successfully${OfflineService.isOnline ? '' : ' (will sync when online)'}'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload users
      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling user status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteUserDialog(AppUser user) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(user);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      if (OfflineService.isOnline) {
        await AuthService.deleteUser(user.id);
      } else {
        // Add to pending changes for offline sync
        await OfflineService.addPendingChange({
          'type': 'delete_user',
          'data': {'id': user.id},
        });
      }

      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'User deleted successfully${OfflineService.isOnline ? '' : ' (will sync when online)'}'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload users
      await _loadUsers();
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
