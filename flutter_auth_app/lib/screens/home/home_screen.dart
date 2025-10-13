import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// Place this helper at the bottom of this file or in a shared utils file:
Future<bool> navigateToHome(BuildContext context) async {
  Navigator.pushReplacementNamed(context, '/home');
  return false;
}

// Usage in scan, history, and skin tips pages:
// Wrap your Scaffold with WillPopScope:
// WillPopScope(
//   onWillPop: () => navigateToHome(context),
//   child: Scaffold(...),
// );

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Index handled by AppBottomNav

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 80,
          flexibleSpace: Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // DermaCare Logo
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow
                                    .withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'DermaCare',
                          style: TextStyle(
                            color: Colors.lightBlue,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    // Settings icon
                    
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/settings'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(auth, theme),

            const SizedBox(height: 24),

            // Quick Actions Section
            _buildQuickActionsSection(theme),

            const SizedBox(height: 16),

            // Quick Actions Grid
            _buildQuickActionsGrid(),

            const SizedBox(height: 80), // Bottom padding for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(AuthProvider auth, ThemeData theme) {
    final greetingText = _getGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface,
              height: 1.2,
              fontSize: 24,
            ),
            children: [
              TextSpan(text: '$greetingText, '),
              TextSpan(
                text: auth.username ?? 'User',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your personal skin care assistant is ready to help you today',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontSize: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cards = [
      {
        'title': 'Skin Analysis',
        'subtitle': 'AI-powered detection',
        'icon': Icons.camera_alt_rounded,
        'color': colorScheme.primary,
        'action': () => Navigator.pushNamed(context, '/skin-analysis'),
      },
      {
        'title': 'Disease Info',
        'subtitle': 'Learn about conditions',
        'icon': Icons.info_outline_rounded,
        'color': colorScheme.secondary,
        'action': () => Navigator.pushNamed(context, '/disease-info'),
      },
      {
        'title': 'History',
        'subtitle': 'View past scans',
        'icon': Icons.history_rounded,
        'color': colorScheme.tertiary,
        'action': () => Navigator.pushNamed(context, '/history'),
      },
      {
        'title': 'Skin Tips',
        'subtitle': 'Get healthy skin advice',
        'icon': Icons.face_retouching_natural,
        'color': colorScheme.secondaryContainer,
        'action': () => Navigator.pushNamed(context, '/skinTips'),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.90, // Taller cards for better icon visibility
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _buildModernActionCard(
          card['title'] as String,
          card['subtitle'] as String,
          card['icon'] as IconData,
          card['color'] as Color,
          card['action'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildModernActionCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: colorScheme.onPrimary,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  // Bottom nav item now provided by AppBottomNav widget.
}
