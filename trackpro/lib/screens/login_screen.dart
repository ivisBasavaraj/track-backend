// File: lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_dashboard.dart';
import 'supervisor_dashboard.dart' as new_supervisor_dashboard;
import 'user_dashboard.dart';
import 'no_task_screen.dart';
import 'incoming_inspection_screen.dart';
import 'finishing_screen.dart';
import 'quality_control_screen.dart';
import 'delivery_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  late final AnimationController _controller;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _backgroundSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardScale = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _backgroundSlide = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    _usernameFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _navigateBasedOnTask(Map<String, dynamic> user) {
    final assignedTask = user['assignedTask'];
    Widget targetScreen;

    if (assignedTask == null) {
      targetScreen = const NoTaskScreen();
    } else {
      switch (assignedTask) {
        case 'Incoming Inspection':
          targetScreen = const IncomingInspectionScreen();
          break;
        case 'Finishing':
          targetScreen = const FinishingScreen();
          break;
        case 'Quality Control':
          targetScreen = const QualityControlScreen();
          break;
        case 'Delivery':
          targetScreen = const DeliveryScreen();
          break;
        default:
          targetScreen = const NoTaskScreen();
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  void _login() async {
    final result = await ApiService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (result['success']) {
      final user = result['user'];
      Widget dashboard;
      switch (user['role']) {
        case 'Admin':
          dashboard = AdminDashboard(adminName: user['name']);
          break;
        case 'Supervisor':
          dashboard = new_supervisor_dashboard
              .SupervisorDashboard(supervisorName: user['name']);
          break;
        case 'User':
          _navigateBasedOnTask(user);
          return;
        default:
          dashboard = AdminDashboard(adminName: user['name']);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => dashboard),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth >= 980;
                  final bool isTablet = constraints.maxWidth >= 680;
                  final bool isCompactHeight = constraints.maxHeight < 760;

                  final EdgeInsets pagePadding = EdgeInsets.symmetric(
                    horizontal: isWide ? 72 : isTablet ? 40 : 22,
                    vertical: isCompactHeight ? 14 : 28,
                  );

                  return Center(
                    child: Padding(
                      padding: pagePadding,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 1180 : 520,
                        ),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _buildWelcomeSection(
                                        isWide,
                                        isCompactHeight,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isCompactHeight ? 28 : 44),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: _buildFormCard(
                                        isWide,
                                        isCompactHeight,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    flex: isCompactHeight ? 4 : 5,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: _buildWelcomeSection(
                                        false,
                                        isCompactHeight,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: isCompactHeight ? 14 : 26,
                                  ),
                                  Flexible(
                                    flex: 5,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: _buildFormCard(
                                        false,
                                        isCompactHeight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _backgroundSlide,
      builder: (context, child) {
        final double slide = _backgroundSlide.value;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF141E30), Color(0xFF243B55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 120 - slide,
                left: -80 + slide,
                child: _buildGlowCircle(220, const Color(0xFF4FACFE)),
              ),
              Positioned(
                bottom: 80 - slide,
                right: -60 + slide,
                child: _buildGlowCircle(180, const Color(0xFF00C6FB)),
              ),
              Positioned(
                top: 60 + slide / 2,
                right: 220,
                child: Opacity(
                  opacity: 0.18 + (_controller.value * 0.1),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 90,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isWide, bool isCompactHeight) {
    final double headingSize = isWide
        ? 46
        : isCompactHeight
            ? 30
            : 36;
    final double bodySize = isCompactHeight ? 14 : 16;
    final double highlightSpacing = isCompactHeight ? 20 : 30;
    final double descriptionSpacing = isCompactHeight ? 12 : 18;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isWide ? 480 : 380,
      ),
      child: FadeTransition(
        opacity: _cardOpacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompactHeight ? 14 : 18,
                vertical: isCompactHeight ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_graph_rounded,
                      color: Colors.white70, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'TrackPro Productivity Suite',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: highlightSpacing),
            Text(
              'Welcome Back',
              textAlign: isWide ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: headingSize,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            SizedBox(height: descriptionSpacing),
            Text(
              'Log in to orchestrate production, monitor tool life, and keep every team aligned in real time.',
              textAlign: isWide ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: bodySize,
                height: 1.55,
              ),
            ),
            SizedBox(height: descriptionSpacing),
            Container(
              padding: EdgeInsets.all(isCompactHeight ? 16 : 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Secure SSO • Session encryption • Role-based dashboards',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isCompactHeight ? 12 : 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isWide, bool isCompactHeight) {
    final double cardPadding = isCompactHeight ? 18 : 28;
    final double headerSize = isCompactHeight ? 20 : 28;
    final double helperSize = isCompactHeight ? 11 : 14;
    final double fieldSpacing = isCompactHeight ? 12 : 22;
    final double betweenSections = isCompactHeight ? 10 : 24;
    final double buttonHeight = isCompactHeight ? 46 : 54;

    return ScaleTransition(
      scale: _cardScale,
      child: FadeTransition(
        opacity: _cardOpacity,
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 38,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 420 : 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Text(
                  'Sign in',
                  style: TextStyle(
                    color: Colors.grey[900],
                    fontSize: headerSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isCompactHeight ? 4 : 6),
                Text(
                  'Enter your credentials to access dashboards.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: helperSize,
                  ),
                ),
                SizedBox(height: betweenSections),
                _buildLabel('Username'),
                SizedBox(height: isCompactHeight ? 6 : 8),
                _buildTextField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  hint: 'Enter your username',
                  icon: Icons.person_outline,
                ),
                SizedBox(height: fieldSpacing),
                _buildLabel('Password'),
                SizedBox(height: isCompactHeight ? 6 : 8),
                _buildTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                SizedBox(height: isCompactHeight ? 6 : 12),
                if (!isCompactHeight)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        textStyle: TextStyle(fontSize: helperSize),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                SizedBox(height: isCompactHeight ? 6 : 12),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double glow = 12 + (_controller.value * 8);
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.35),
                            blurRadius: glow,
                            spreadRadius: _controller.value * 2,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                          fontSize: isCompactHeight ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Sign In'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: betweenSections),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 30, height: 1, color: Colors.grey[300]),
                    const SizedBox(width: 12),
                    Text(
                      'Powered by TrackPro',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 30, height: 1, color: Colors.grey[300]),
                  ],
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.grey[700],
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    final bool hasFocus = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword,
        obscuringCharacter: '•',
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: hasFocus ? const Color(0xFF4F46E5) : Colors.grey[500],
          ),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:
                const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
          ),
        ),
      ),
    );
  }
}