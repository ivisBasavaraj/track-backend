// File: lib/screens/modern_login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../ui/app_theme.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_loading.dart';
import 'admin_dashboard.dart';
import 'supervisor_dashboard.dart' as new_supervisor_dashboard;
import 'user_dashboard.dart';
import 'no_task_screen.dart';
import 'incoming_inspection_screen.dart';
import 'finishing_screen.dart';
import 'quality_control_screen.dart';
import 'delivery_screen.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _slideController.forward();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                CurveTween(curve: Curves.easeInOut),
              ),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (result['success']) {
        HapticFeedback.mediumImpact();
        final user = result['user'];

        // Update FCM Token after successful login
        try {
          String? fcmToken = await ApiService.getToken(); // Wait, this is auth token
          // I need to get FCM token from FCMService
          String? fcmTokenReal = await FCMService.getToken();
          if (fcmTokenReal != null) {
            await ApiService.updateFcmToken(fcmTokenReal);
            print('FCM Token updated on login');
          }
        } catch (fcmError) {
          print('Failed to update FCM token on login: $fcmError');
        }

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
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => dashboard,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        HapticFeedback.lightImpact();
        _showErrorSnackBar(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      HapticFeedback.lightImpact();
      _showErrorSnackBar('Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTheme.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.backgroundColor,
              AppTheme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimationLimiter(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 400),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 48),
                      _buildLoginCard(),
                      const SizedBox(height: 24),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final logoSize = screenWidth < 400 ? 70.0 : screenWidth < 600 ? 90.0 : 110.0;
            final iconSize = logoSize * 0.5;

            return Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.7),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.precision_manufacturing,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: screenWidth < 400 ? 16 : 24),
                Text(
                  'TrackPro',
                  style: AppTheme.headlineLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: screenWidth < 400 ? 28 : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Production Management System',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                    fontSize: screenWidth < 400 ? 12 : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth < 400 ? 20.0 : screenWidth < 600 ? 24.0 : 32.0;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ModernCard(
        padding: EdgeInsets.all(cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome Back',
                style: AppTheme.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your account',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildUsernameField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildRememberMeRow(),
              const SizedBox(height: 32),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      focusNode: _usernameFocusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your username';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Username',
        hintText: 'Enter your username',
        prefixIcon: Icon(
          Icons.person_outline,
          color: _usernameFocusNode.hasFocus
              ? AppTheme.primaryColor
              : AppTheme.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 3) {
          return 'Password must be at least 3 characters';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: _passwordFocusNode.hasFocus
              ? AppTheme.primaryColor
              : AppTheme.textSecondary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.surfaceColor,
      ),
    );
  }

  Widget _buildRememberMeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                  HapticFeedback.lightImpact();
                },
                activeColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Remember me',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            // Handle forgot password
            HapticFeedback.lightImpact();
          },
          child: Text(
            'Forgot Password?',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    if (_isLoading) {
      return const ModernButton(
        text: 'Signing In...',
        onPressed: null,
        isLoading: true,
      );
    }

    return ModernButton(
      text: 'Sign In',
      onPressed: _handleLogin,
      style: ModernButtonStyle.primary,
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/fcm-test');
          },
          icon: const Icon(Icons.notifications_active, size: 16),
          label: const Text('Test FCM'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '© 2024 TrackPro. All rights reserved.',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Version 2.0.0',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}