import 'package:flutter/material.dart';

void main() {
  runApp(const SkinSyncApp());
}

class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const skinProfileSetup = '/skin-profile-setup';
  static const home = '/home';
  static const aiUpload = '/ai-upload';
  static const aiLoading = '/ai-loading';
  static const aiResult = '/ai-result';
  static const routineSuggestion = '/routine-suggestion';
  static const routine = '/routine';
  static const editRoutine = '/edit-routine';
  static const products = '/products';
  static const productDetail = '/product-detail';
  static const selectRoutineStep = '/select-routine-step';
  static const tracking = '/tracking';
  static const dailyLog = '/daily-log';
  static const dailyLogDetail = '/daily-log-detail';
  static const reminders = '/reminders';
  static const addReminder = '/add-reminder';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const settings = '/settings';

  static const mainTabs = <String>[
    home,
    aiUpload,
    routine,
    tracking,
    profile,
  ];
}

class SkinSyncApp extends StatefulWidget {
  const SkinSyncApp({super.key});

  @override
  State<SkinSyncApp> createState() => _SkinSyncAppState();
}

class _SkinSyncAppState extends State<SkinSyncApp> {
  final AppState appState = AppState();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SkinSync',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD97757),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFFFF9F4),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFFF9F4),
              foregroundColor: Color(0xFF2A211C),
              elevation: 0,
              centerTitle: false,
            ),
            cardTheme: CardTheme(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFF0DDD2)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE9D6CA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE9D6CA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFD97757), width: 1.6),
              ),
            ),
          ),
          initialRoute: AppRoutes.splash,
          onGenerateRoute: (settings) {
            final routeName = _guardRoute(settings.name ?? AppRoutes.splash);
            return MaterialPageRoute<void>(
              settings: RouteSettings(name: routeName),
              builder: (context) => _buildScreen(routeName),
            );
          },
        );
      },
    );
  }

  String _guardRoute(String route) {
    if (route == AppRoutes.splash) {
      return AppRoutes.splash;
    }

    if (!appState.isLoggedIn) {
      const publicRoutes = {
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      };
      return publicRoutes.contains(route) ? route : AppRoutes.welcome;
    }

    if (!appState.hasSkinProfile) {
      return route == AppRoutes.skinProfileSetup ? route : AppRoutes.skinProfileSetup;
    }

    return route;
  }

  Widget _buildScreen(String route) {
    switch (route) {
      case AppRoutes.splash:
        return SplashScreen(appState: appState);
      case AppRoutes.welcome:
        return WelcomeScreen(appState: appState);
      case AppRoutes.login:
        return LoginScreen(appState: appState);
      case AppRoutes.register:
        return RegisterScreen(appState: appState);
      case AppRoutes.forgotPassword:
        return const ForgotPasswordScreen();
      case AppRoutes.skinProfileSetup:
        return SkinProfileSetupScreen(appState: appState);
      case AppRoutes.home:
        return MainShell(appState: appState, currentRoute: route, child: HomeScreen(appState: appState));
      case AppRoutes.aiUpload:
        return MainShell(appState: appState, currentRoute: route, child: const AiUploadScreen());
      case AppRoutes.aiLoading:
        return const AiLoadingScreen();
      case AppRoutes.aiResult:
        return const AiResultScreen();
      case AppRoutes.routineSuggestion:
        return const RoutineSuggestionScreen();
      case AppRoutes.routine:
        return MainShell(appState: appState, currentRoute: route, child: const RoutineScreen());
      case AppRoutes.editRoutine:
        return const EditRoutineScreen();
      case AppRoutes.products:
        return const ProductScreen();
      case AppRoutes.productDetail:
        return const ProductDetailScreen();
      case AppRoutes.selectRoutineStep:
        return const SelectRoutineStepScreen();
      case AppRoutes.tracking:
        return MainShell(appState: appState, currentRoute: route, child: const TrackingScreen());
      case AppRoutes.dailyLog:
        return const DailyLogScreen();
      case AppRoutes.dailyLogDetail:
        return const DailyLogDetailScreen();
      case AppRoutes.reminders:
        return const ReminderScreen();
      case AppRoutes.addReminder:
        return const AddReminderScreen();
      case AppRoutes.profile:
        return MainShell(appState: appState, currentRoute: route, child: ProfileScreen(appState: appState));
      case AppRoutes.editProfile:
        return const EditProfileScreen();
      case AppRoutes.settings:
        return SettingsScreen(appState: appState);
      default:
        return WelcomeScreen(appState: appState);
    }
  }
}

class AppState extends ChangeNotifier {
  bool isLoggedIn = false;
  bool hasSkinProfile = false;

  void login() {
    isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    hasSkinProfile = false;
    notifyListeners();
  }

  void completeSkinProfile() {
    hasSkinProfile = true;
    notifyListeners();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      final route = !widget.appState.isLoggedIn
          ? AppRoutes.welcome
          : widget.appState.hasSkinProfile
              ? AppRoutes.home
              : AppRoutes.skinProfileSetup;
      Navigator.pushReplacementNamed(context, route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientPage(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE2D4),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.spa_rounded, size: 56, color: Color(0xFFD97757)),
            ),
            const SizedBox(height: 24),
            Text(
              'SkinSync',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2A211C),
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'AI-powered skincare guidance tailored to your routine.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return GradientPage(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.spa_rounded, size: 52, color: Color(0xFFD97757)),
              ),
              const SizedBox(height: 18),
              Text(
                'SkinSync',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A211C),
                    ),
              ),
              const Spacer(),
              Text(
                'Build a skincare plan that fits your skin, not just the trend.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A211C),
                    ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SkinSync helps you create a skin profile, analyze concerns with AI, and stay on track with reminders and daily logs.',
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                child: const Text('Login'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                child: const Text('Register'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  appState.login();
                  appState.completeSkinProfile();
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
                },
                child: const Text('Preview authenticated app'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Login',
      subtitle: 'Sign in to continue your skincare journey.',
      children: [
        const LabeledField(label: 'Email'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Password', obscureText: true),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
            child: const Text('Forgot password?'),
          ),
        ),
        FilledButton(
          onPressed: () {
            appState.login();
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.skinProfileSetup, (_) => false);
          },
          child: const Text('Login'),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
          child: const Text('Create an account'),
        ),
      ],
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Register',
      subtitle: 'Create your SkinSync account and set up your skin profile.',
      children: [
        const LabeledField(label: 'Full name'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Email'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Password', obscureText: true),
        const SizedBox(height: 12),
        const LabeledField(label: 'Confirm password', obscureText: true),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            appState.login();
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.skinProfileSetup, (_) => false);
          },
          child: const Text('Register'),
        ),
      ],
    );
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Forgot Password',
      subtitle: 'Enter your email to receive a reset link.',
      children: [
        const LabeledField(label: 'Email'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Send reset link'),
        ),
      ],
    );
  }
}

class SkinProfileSetupScreen extends StatelessWidget {
  const SkinProfileSetupScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Skin Profile Setup',
      subtitle: 'Capture the essentials so SkinSync can personalize recommendations.',
      children: [
        const TagWrap(title: 'Skin type', items: ['Oily', 'Dry', 'Combination', 'Normal', 'Sensitive']),
        const SizedBox(height: 12),
        const TagWrap(title: 'Skin concerns', items: ['Acne', 'Dark spots', 'Wrinkles', 'Redness', 'Dryness']),
        const SizedBox(height: 12),
        const LabeledField(label: 'Allergies or ingredients to avoid'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Skincare goals'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            appState.completeSkinProfile();
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
          },
          child: const Text('Save profile'),
        ),
      ],
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.appState,
    required this.currentRoute,
    required this.child,
  });

  final AppState appState;
  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final routeIndex = AppRoutes.mainTabs.indexOf(currentRoute);
    final index = routeIndex >= 0 ? routeIndex : 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (selectedIndex) {
          Navigator.pushReplacementNamed(context, AppRoutes.mainTabs[selectedIndex]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Routine'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Tracking'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Home',
      action: IconButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
        icon: const Icon(Icons.tune_rounded),
      ),
      children: [
        const HeroBanner(
          title: 'Good morning, your skin plan is ready.',
          description: 'Review today\'s routine, your latest AI analysis, and the next reminder in one place.',
        ),
        const SizedBox(height: 16),
        const TwoColumnStats(),
        const SizedBox(height: 16),
        NavigationCard(
          title: 'AI Skin Analysis',
          description: 'Upload or capture a photo to detect skin concerns and generate a personalized routine.',
          cta: 'Start analysis',
          onTap: () => Navigator.pushNamed(context, AppRoutes.aiUpload),
        ),
        NavigationCard(
          title: 'Today\'s Routine',
          description: 'Check your morning and night steps and mark them complete.',
          cta: 'Open routine',
          onTap: () => Navigator.pushNamed(context, AppRoutes.routine),
        ),
        NavigationCard(
          title: 'Progress Tracking',
          description: 'Log your skin condition and monitor changes over time.',
          cta: 'View tracking',
          onTap: () => Navigator.pushNamed(context, AppRoutes.tracking),
        ),
        NavigationCard(
          title: 'Product Library',
          description: 'Browse skincare products and ingredient fit warnings.',
          cta: 'Browse products',
          onTap: () => Navigator.pushNamed(context, AppRoutes.products),
        ),
        OutlinedButton(
          onPressed: () {
            appState.logout();
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

class AiUploadScreen extends StatelessWidget {
  const AiUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'AI Upload',
      children: [
        const HeroBanner(
          title: 'Take a clear photo',
          description: 'Use natural light, remove filters, and keep your full face in frame for better analysis.',
        ),
        Card(
          child: Container(
            height: 220,
            alignment: Alignment.center,
            child: const Icon(Icons.add_a_photo_outlined, size: 72, color: Color(0xFFD97757)),
          ),
        ),
        const SizedBox(height: 16),
        const ActionGroup(labels: ['Take Photo', 'Upload from Gallery']),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.aiLoading),
          child: const Text('Analyze'),
        ),
      ],
    );
  }
}

class AiLoadingScreen extends StatefulWidget {
  const AiLoadingScreen({super.key});

  @override
  State<AiLoadingScreen> createState() => _AiLoadingScreenState();
}

class _AiLoadingScreenState extends State<AiLoadingScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.aiResult);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientPage(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('AI is analyzing your skin...'),
                  SizedBox(height: 8),
                  Text('Checking skin type, concern severity, and routine fit.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AiResultScreen extends StatelessWidget {
  const AiResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'AI Result',
      children: [
        const HeroBanner(
          title: 'Combination skin with active redness and mild acne',
          description: 'The current analysis suggests barrier support, gentle cleansing, and consistent sunscreen use.',
        ),
        const SectionCard(
          title: 'Detected concerns',
          lines: [
            'Acne: Mild',
            'Redness: Moderate',
            'Dryness: Mild',
            'Dark spots: Low',
          ],
        ),
        const SectionCard(
          title: 'AI care suggestions',
          lines: [
            'Use a gentle cleanser morning and night.',
            'Prioritize calming serum and lightweight moisturizer.',
            'Avoid strong exfoliants on irritated days.',
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.routineSuggestion),
          child: const Text('Generate routine'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => route.isFirst),
          child: const Text('Save result'),
        ),
      ],
    );
  }
}

class RoutineSuggestionScreen extends StatelessWidget {
  const RoutineSuggestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Routine Suggestion',
      children: [
        const SectionCard(
          title: 'Morning routine',
          lines: ['Gentle cleanser', 'Niacinamide serum', 'Barrier moisturizer', 'SPF 50 sunscreen'],
        ),
        const SectionCard(
          title: 'Night routine',
          lines: ['Gentle cleanser', 'Calming serum', 'Treatment for acne spots', 'Repair cream'],
        ),
        const SectionCard(
          title: 'Usage notes',
          lines: [
            'Patch test any new treatment first.',
            'Introduce active ingredients slowly.',
            'Reassess after 2-3 weeks of consistent use.',
          ],
        ),
        FilledButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.routine, (_) => false),
          child: const Text('Save routine'),
        ),
      ],
    );
  }
}

class RoutineScreen extends StatelessWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Routine',
      children: [
        const SectionCard(
          title: 'Morning',
          lines: ['Cleanser', 'Serum', 'Moisturizer', 'Sunscreen'],
        ),
        const SectionCard(
          title: 'Night',
          lines: ['Cleanser', 'Treatment', 'Moisturizer'],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.editRoutine),
          child: const Text('Edit routine'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.reminders),
          child: const Text('Add reminder'),
        ),
      ],
    );
  }
}

class EditRoutineScreen extends StatelessWidget {
  const EditRoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Edit Routine',
      subtitle: 'Adjust the order, products, and schedule of your skincare steps.',
      children: [
        const SectionCard(
          title: 'Editable steps',
          lines: [
            'Add or remove skincare steps',
            'Change the order of application',
            'Assign products to morning or night',
          ],
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tracking',
      children: [
        const TwoColumnStats(
          leftTitle: 'Routine completion',
          leftValue: '86%',
          rightTitle: 'Weekly logs',
          rightValue: '5/7',
        ),
        const SizedBox(height: 16),
        const SectionCard(
          title: 'This week',
          lines: [
            'Mon: Routine completed',
            'Tue: Mild redness noted',
            'Wed: No irritation',
            'Thu: Added calming mask',
          ],
        ),
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.dailyLog),
          child: const Text('Add daily log'),
        ),
      ],
    );
  }
}

class DailyLogScreen extends StatelessWidget {
  const DailyLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Daily Log',
      subtitle: 'Capture how your skin feels today to build a clearer progress history.',
      children: [
        const LabeledField(label: 'Skin condition'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Acne level'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Dryness level'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Irritation level'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Notes'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.dailyLogDetail),
          child: const Text('Save log'),
        ),
      ],
    );
  }
}

class DailyLogDetailScreen extends StatelessWidget {
  const DailyLogDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Daily Log Detail',
      children: [
        const SectionCard(
          title: 'Today\'s summary',
          lines: [
            'Condition: Calm with mild dryness',
            'Acne level: 2/5',
            'Irritation: 1/5',
            'Routine completed: Morning + Night',
          ],
        ),
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.dailyLog),
          child: const Text('Edit log'),
        ),
      ],
    );
  }
}

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reminders',
      children: [
        const SectionCard(
          title: 'Active reminders',
          lines: [
            '07:00 AM - Morning routine',
            '09:00 PM - Night routine',
            'Sunday - Weekly progress check',
          ],
        ),
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.addReminder),
          child: const Text('Add reminder'),
        ),
      ],
    );
  }
}

class AddReminderScreen extends StatelessWidget {
  const AddReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Add Reminder',
      subtitle: 'Choose the time, routine, and repeat pattern for notifications.',
      children: [
        const LabeledField(label: 'Time'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Routine type'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Repeat days'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Save reminder'),
        ),
      ],
    );
  }
}

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Products',
      children: [
        const LabeledField(label: 'Search products'),
        const SizedBox(height: 12),
        const TagWrap(title: 'Filters', items: ['Cleanser', 'Serum', 'Moisturizer', 'Sunscreen', 'Sensitive skin']),
        const SizedBox(height: 16),
        NavigationCard(
          title: 'Barrier Support Moisturizer',
          description: 'Suitable for combination and sensitive skin with calming ingredients.',
          cta: 'View details',
          onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail),
        ),
      ],
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Product Detail',
      children: [
        const SectionCard(
          title: 'Barrier Support Moisturizer',
          lines: [
            'Type: Moisturizer',
            'Best for: Sensitive, combination skin',
            'Key ingredients: Ceramides, panthenol, glycerin',
            'Warning: Avoid if you react to shea derivatives',
          ],
        ),
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.selectRoutineStep),
          child: const Text('Add to routine'),
        ),
      ],
    );
  }
}

class SelectRoutineStepScreen extends StatelessWidget {
  const SelectRoutineStepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Select Routine Step',
      subtitle: 'Choose when this product should appear in your routine.',
      children: [
        const LabeledField(label: 'Morning or night'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Skincare step'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.routine, (_) => false),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile',
      children: [
        const SectionCard(
          title: 'Skin profile',
          lines: [
            'Name: SkinSync User',
            'Skin type: Combination',
            'Concerns: Redness, acne, dryness',
            'Goal: Calm irritation and strengthen barrier',
          ],
        ),
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile),
          child: const Text('Edit profile'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          child: const Text('Settings'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            appState.logout();
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Edit Profile',
      subtitle: 'Update the personal and skin details SkinSync uses for personalization.',
      children: [
        const LabeledField(label: 'Full name'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Age'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Gender'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Skin type'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Skin concerns'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Allergies'),
        const SizedBox(height: 12),
        const LabeledField(label: 'Skincare goals'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      children: [
        const SectionCard(
          title: 'App settings',
          lines: [
            'Notifications: Enabled',
            'Language: English',
            'Theme: Light',
            'Privacy policy and terms of service available here',
          ],
        ),
        OutlinedButton(
          onPressed: () {
            appState.logout();
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
          },
          child: const Text('Delete account (placeholder)'),
        ),
      ],
    );
  }
}

class GradientPage extends StatelessWidget {
  const GradientPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF6F0), Color(0xFFFFE7D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    );
  }
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.children,
    this.action,
  });

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: action == null ? null : [action!]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: children,
      ),
    );
  }
}

class FormScaffold extends StatelessWidget {
  const FormScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      children: [
        Text(subtitle),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(description),
          ],
        ),
      ),
    );
  }
}

class NavigationCard extends StatelessWidget {
  const NavigationCard({
    super.key,
    required this.title,
    required this.description,
    required this.cta,
    required this.onTap,
  });

  final String title;
  final String description;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 14),
            FilledButton(onPressed: onTap, child: Text(cta)),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...lines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(line)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class TwoColumnStats extends StatelessWidget {
  const TwoColumnStats({
    super.key,
    this.leftTitle = 'Next reminder',
    this.leftValue = '07:00 AM',
    this.rightTitle = 'Streak',
    this.rightValue = '12 days',
  });

  final String leftTitle;
  final String leftValue;
  final String rightTitle;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: StatCard(title: leftTitle, value: leftValue)),
        const SizedBox(width: 12),
        Expanded(child: StatCard(title: rightTitle, value: rightValue)),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.obscureText = false,
  });

  final String label;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class TagWrap extends StatelessWidget {
  const TagWrap({super.key, required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => Chip(
                      label: Text(item),
                      backgroundColor: const Color(0xFFFFEFE4),
                      side: const BorderSide(color: Color(0xFFF0DDD2)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionGroup extends StatelessWidget {
  const ActionGroup({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: labels
          .map(
            (label) => OutlinedButton(
              onPressed: () {},
              child: Text(label),
            ),
          )
          .toList(),
    );
  }
}
