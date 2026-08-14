import 'package:flutter/material.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // Method to handle drawer item taps and navigate to selected route
  void _handleDrawerItemTap(String routeName) {
    Navigator.pop(context); // Close the drawer
    Navigator.pushNamed(context, routeName); // Navigate to the selected route
  }

  // Method to build the drawer item
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String routeName,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      onTap: () => _handleDrawerItemTap(routeName),
    );
  }

  // Method to build an elevated button with enhanced style and functionality
  Widget _buildElevatedButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : Container(),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications action
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const UserAccountsDrawerHeader(
              accountName: Text('Admin Name'),
              accountEmail: Text('admin@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              routeName: '/dashboard',
            ),
            _buildDrawerItem(
              icon: Icons.people,
              title: 'Manage Users',
              routeName: '/manageUsers',
            ),
            _buildDrawerItem(
              icon: Icons.report,
              title: 'View Reports',
              routeName: '/viewReports',
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              routeName: '/settings',
            ),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              routeName: '/logout',
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Welcome, Admin!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildElevatedButton(
              text: 'Manage Users',
              icon: Icons.people,
              onPressed: () {
                Navigator.pushNamed(context, '/manageUsers');
              },
            ),
            _buildElevatedButton(
              text: 'View Reports',
              icon: Icons.report,
              onPressed: () {
                Navigator.pushNamed(context, '/viewReports');
              },
            ),
            _buildElevatedButton(
              text: 'Settings',
              icon: Icons.settings,
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const SizedBox(height: 20),
            _buildElevatedButton(
              text: 'Logout',
              icon: Icons.logout,
              onPressed: () {
                Navigator.pushNamed(context, '/logout');
              },
            ),
          ],
        ),
      ),
    );
  }
}
