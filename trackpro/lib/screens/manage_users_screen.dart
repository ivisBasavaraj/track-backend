// File: lib/screens/manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/api_service.dart';
import '../ui/app_theme.dart';
import '../widgets/modern_card.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final List<String> _roles = ['User', 'Supervisor', 'Admin'];
  String _selectedRole = 'User';
  
  // Sample user data - in real app, this would come from a database
  List<User> users = [
    User(
      id: '001',
      name: 'John Smith',
      username: 'john.smith',
      role: 'Supervisor',
      isActive: true,
      todayTasks: [
        Task('Incoming Inspection', 'Batch #IN-2024-098', 'Completed', AppTheme.successColor),
        Task('Quality Control', 'Part ID: QC-2024-045', 'In Progress', AppTheme.warningColor),
      ],
      completedToday: 8,
      totalAssigned: 12,
    ),
    User(
      id: '002',
      name: 'Sarah Johnson',
      username: 'sarah.johnson',
      role: 'User',
      isActive: true,
      todayTasks: [
        Task('Finishing Operations', 'AMS-141 COLUMN', 'In Progress', AppTheme.primaryColor),
        Task('Delivery Management', 'Order #DEL-445', 'Completed', AppTheme.successColor),
        Task('Incoming Inspection', 'Component Check', 'Pending', AppTheme.subtitleColor),
      ],
      completedToday: 6,
      totalAssigned: 9,
    ),
    User(
      id: '003',
      name: 'Mike Rodriguez',
      username: 'mike.rodriguez',
      role: 'User',
      isActive: false,
      todayTasks: [],
      completedToday: 0,
      totalAssigned: 0,
    ),
    User(
      id: '004',
      name: 'Emily Chen',
      username: 'emily.chen',
      role: 'Admin',
      isActive: true,
      todayTasks: [
        Task('Management', 'Weekly Reports', 'In Progress', AppTheme.primaryColor),
        Task('Quality Review', 'System Check', 'Completed', AppTheme.successColor),
      ],
      completedToday: 4,
      totalAssigned: 6,
    ),
    User(
      id: '005',
      name: 'David Wilson',
      username: 'david.wilson',
      role: 'Supervisor',
      isActive: true,
      todayTasks: [
        Task('Training', 'New Employee Orientation', 'Completed', AppTheme.successColor),
        Task('Quality Control', 'Final Inspection', 'In Progress', AppTheme.warningColor),
        Task('Documentation', 'Process Updates', 'Pending', AppTheme.subtitleColor),
      ],
      completedToday: 5,
      totalAssigned: 8,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Manage Users',
          style: AppTheme.headingStyle.copyWith(
            color: AppTheme.primaryColor,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.subtitleColor,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: AppTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.people_outline),
              text: 'Team Overview',
            ),
            Tab(
              icon: Icon(Icons.person_add_outlined),
              text: 'Add Member',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserListTab(),
          _buildAddUserTab(),
        ],
      ),
    );
  }

  Widget _buildUserListTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimationLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: [
              // Welcome Header
              ModernCard(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.accentColor.withOpacity(0.05),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team Management',
                        style: AppTheme.headingStyle.copyWith(
                          fontSize: 20,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monitor team performance and manage user roles',
                        style: AppTheme.subtitleStyle,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              
              // Summary Cards
              _buildSummarySection(),
              const SizedBox(height: 25),
              
              // Users List
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.accentColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Team Members',
                    style: AppTheme.headingStyle.copyWith(
                      fontSize: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              ...users.map((user) => _buildUserCard(user)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    int activeUsers = users.where((u) => u.isActive).length;
    int totalUsers = users.length;
    int totalTasksCompleted = users.fold(0, (sum, user) => sum + user.completedToday);
    int totalTasksAssigned = users.fold(0, (sum, user) => sum + user.totalAssigned);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.accentColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Team Overview',
              style: AppTheme.headingStyle.copyWith(
                fontSize: 18,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Active Users',
                '$activeUsers/$totalUsers',
                Icons.people_outline,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Tasks Today',
                '$totalTasksCompleted/$totalTasksAssigned',
                Icons.assignment_outlined,
                AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Supervisors',
                '${users.where((u) => u.role == 'Supervisor').length}',
                Icons.supervisor_account_outlined,
                AppTheme.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Efficiency',
                '${totalTasksAssigned > 0 ? ((totalTasksCompleted / totalTasksAssigned) * 100).toInt() : 0}%',
                Icons.trending_up,
                AppTheme.warningColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return ModernCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.8),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTheme.headingStyle.copyWith(
                fontSize: 18,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppTheme.subtitleStyle.copyWith(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: user.isActive 
                          ? [AppTheme.successColor.withOpacity(0.8), AppTheme.successColor]
                          : [AppTheme.subtitleColor.withOpacity(0.8), AppTheme.subtitleColor],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (user.isActive ? AppTheme.successColor : AppTheme.subtitleColor).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user.name.split(' ').map((n) => n[0]).join(''),
                      style: AppTheme.headingStyle.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.name,
                            style: AppTheme.headingStyle.copyWith(
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: user.isActive ? AppTheme.successColor.withOpacity(0.1) : AppTheme.subtitleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: user.isActive ? AppTheme.successColor : AppTheme.subtitleColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              user.isActive ? 'Active' : 'Inactive',
                              style: AppTheme.captionStyle.copyWith(
                                color: user.isActive ? AppTheme.successColor : AppTheme.subtitleColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: AppTheme.subtitleStyle,
                      ),
                    ],
                  ),
                ),
                // Role Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: user.role,
                      style: AppTheme.subtitleStyle.copyWith(fontSize: 12),
                      onChanged: (String? newRole) {
                        setState(() {
                          user.role = newRole!;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${user.name}\'s role updated to $newRole'),
                            backgroundColor: AppTheme.successColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      items: _roles.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress Bar
            Row(
              children: [
                Text(
                  'Today\'s Progress: ${user.completedToday}/${user.totalAssigned}',
                  style: AppTheme.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${user.totalAssigned > 0 ? ((user.completedToday / user.totalAssigned) * 100).toInt() : 0}%',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.subtitleColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: user.totalAssigned > 0 ? user.completedToday / user.totalAssigned : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        user.totalAssigned > 0 && user.completedToday / user.totalAssigned > 0.8 
                            ? AppTheme.successColor
                            : user.totalAssigned > 0 && user.completedToday / user.totalAssigned > 0.5 
                                ? AppTheme.warningColor
                                : AppTheme.accentColor,
                        user.totalAssigned > 0 && user.completedToday / user.totalAssigned > 0.8 
                            ? AppTheme.successColor.withOpacity(0.8)
                            : user.totalAssigned > 0 && user.completedToday / user.totalAssigned > 0.5 
                                ? AppTheme.warningColor.withOpacity(0.8)
                                : AppTheme.accentColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: (user.totalAssigned > 0 && user.completedToday / user.totalAssigned > 0.8 
                            ? AppTheme.successColor
                            : user.totalAssigned > 0 && user.completedToday / user.totalAssigned > 0.5 
                                ? AppTheme.warningColor
                                : AppTheme.accentColor).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Today's Tasks
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Tasks',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                ...user.todayTasks.map((task) => _buildTaskItem(task)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [task.statusColor.withOpacity(0.8), task.statusColor],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: task.statusColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${task.type}: ${task.description}',
              style: AppTheme.bodyStyle,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  task.statusColor.withOpacity(0.1),
                  task.statusColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: task.statusColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              task.status,
              style: AppTheme.captionStyle.copyWith(
                color: task.statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddUserTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AnimationLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: [
              // Header
              ModernCard(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.accentColor.withOpacity(0.1),
                        AppTheme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.accentColor,
                                  AppTheme.primaryColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_add_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add New Team Member',
                                  style: AppTheme.headingStyle.copyWith(
                                    fontSize: 20,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fill in the details below to add a new user to your team',
                                  style: AppTheme.subtitleStyle,
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
              const SizedBox(height: 30),

              ModernCard(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildInputField('Full Name', _nameController, 'Enter full name', Icons.person_outline),
                      const SizedBox(height: 20),
                      _buildInputField('Username', _usernameController, 'Enter username', Icons.alternate_email),
                      const SizedBox(height: 20),
                      _buildInputField('Password', _passwordController, 'Enter password', Icons.lock_outline, isPassword: true),
                      const SizedBox(height: 20),
                      
                      // Role Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Role',
                                style: AppTheme.headingStyle.copyWith(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRole,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedRole = newValue!;
                                  });
                                },
                                items: _roles.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: AppTheme.bodyStyle,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Add Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.accentColor],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _addUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person_add,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add Team Member',
                                style: AppTheme.buttonTextStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.headingStyle.copyWith(
                fontSize: 14,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: AppTheme.bodyStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.subtitleStyle,
            filled: true,
            fillColor: AppTheme.primaryColor.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  void _addUser() async {
    if (_nameController.text.isNotEmpty && 
        _usernameController.text.isNotEmpty && 
        _passwordController.text.isNotEmpty) {
      
      final result = await ApiService.registerUser(
        _nameController.text,
        _usernameController.text,
        _passwordController.text,
        _selectedRole,
      );
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text} added successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Clear form
        _nameController.clear();
        _usernameController.clear();
        _passwordController.clear();
        setState(() {
          _selectedRole = 'User';
        });
        
        // Refresh user list
        _loadUsers();
        _tabController.animateTo(0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  void _loadUsers() async {
    try {
      final userList = await ApiService.getUsers();
      setState(() {
        users = userList.map((userData) => User(
          id: userData['_id'],
          name: userData['name'],
          username: userData['username'],
          role: userData['role'],
          isActive: userData['isActive'],
          todayTasks: [],
          completedToday: userData['completedToday'] ?? 0,
          totalAssigned: userData['totalAssigned'] ?? 0,
        )).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load users: $e'),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Data Models
class User {
  final String id;
  String name;
  String username;
  String role;
  bool isActive;
  List<Task> todayTasks;
  int completedToday;
  int totalAssigned;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.isActive,
    required this.todayTasks,
    required this.completedToday,
    required this.totalAssigned,
  });
}

class Task {
  final String type;
  final String description;
  final String status;
  final Color statusColor;

  Task(this.type, this.description, this.status, this.statusColor);
}