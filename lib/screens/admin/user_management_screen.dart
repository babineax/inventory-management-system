import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<AppUser> users = [];
  List<AppUser> filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _filterUsers() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          return user.displayName.toLowerCase().contains(_searchQuery) ||
              user.email.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await _firestore.collection('users').get();
      users = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();
      filteredUsers = users;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('users').doc(user.id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName} deleted successfully')),
        );
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e')),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).update({
        'isActive': !user.isActive,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${user.displayName} status updated to ${!user.isActive ? 'active' : 'inactive'}')),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user status: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _promoteToAdmin(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: Text(
            'Are you sure you want to promote ${user.displayName} to admin? This will grant them full access to the system.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('PROMOTE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AuthService.promoteUserToAdmin(user.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName} promoted to admin')),
        );
        _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to promote user')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          user.displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user.displayName),
                      subtitle: Row(
                        children: [
                          Text(user.email),
                          const SizedBox(width: 8),
                          if (!user.isActive)
                            const Chip(
                              label: Text('Inactive'),
                              backgroundColor: Colors.red,
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(
                              user.isAdmin ? 'Admin' : 'Staff',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor:
                                user.isAdmin ? Colors.purple : Colors.blue,
                          ),
                          if (!user.isAdmin)
                            IconButton(
                              icon: const Icon(Icons.admin_panel_settings),
                              tooltip: 'Promote to Admin',
                              onPressed: () => _promoteToAdmin(user),
                            ),
                          IconButton(
                            icon: Icon(
                              user.isActive
                                  ? Icons.toggle_off
                                  : Icons.toggle_on,
                              color: user.isActive ? Colors.red : Colors.green,
                            ),
                            tooltip: user.isActive
                                ? 'Deactivate User'
                                : 'Activate User',
                            onPressed: () => _toggleUserStatus(user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete User',
                            onPressed: () => _deleteUser(user),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
