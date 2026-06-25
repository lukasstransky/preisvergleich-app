import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'providers/app_state.dart';
import 'screens/main_screen.dart';
import 'theme/app_colors.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Preisvergleich',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
            surface: AppColors.surface,
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            error: AppColors.danger,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.bg,
          canvasColor: AppColors.bg,
          dividerColor: AppColors.border,
          textTheme: Typography.whiteMountainView.apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: AppColors.bg,
            foregroundColor: AppColors.textPrimary,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            actionsIconTheme: IconThemeData(color: AppColors.textSecondary),
          ),
          // Cards are differentiated by surface colour + hairline border, not shadow.
          cardTheme: const CardThemeData(
            elevation: 0,
            color: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            margin: EdgeInsets.zero,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: 64,
            indicatorColor: AppColors.primarySoft,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 24,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              );
            }),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          chipTheme: ChipThemeData(
            side: BorderSide.none,
            backgroundColor: AppColors.surfaceAlt,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
            contentTextStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: AppColors.surfaceHigh,
            contentTextStyle: TextStyle(color: AppColors.textPrimary),
            behavior: SnackBarBehavior.floating,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surfaceAlt,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.border,
            thickness: 1,
            space: 0,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}
