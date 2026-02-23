import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  runApp(const ZenithApp());
}

class ZenithApp extends StatelessWidget {
  const ZenithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProxyProvider<TaskProvider, ChatProvider>(
          create: (context) => ChatProvider(context.read<TaskProvider>()),
          update: (context, taskProvider, chatProvider) =>
              chatProvider ?? ChatProvider(taskProvider),
        ),
        // AuthProvider is created last so it can receive references to the
        // data providers and clear them on sign-out / user switch.
        ChangeNotifierProxyProvider3<TaskProvider, JournalProvider, ChatProvider, AuthProvider>(
          create: (context) {
            final auth = AuthProvider();
            auth.setDataProviders(
              taskProvider: context.read<TaskProvider>(),
              journalProvider: context.read<JournalProvider>(),
              chatProvider: context.read<ChatProvider>(),
            );
            return auth;
          },
          update: (context, taskProvider, journalProvider, chatProvider, auth) {
            // Update references whenever the proxy rebuilds (e.g. ChatProvider
            // reference changes when TaskProvider updates)
            auth!.setDataProviders(
              taskProvider: taskProvider,
              journalProvider: journalProvider,
              chatProvider: chatProvider,
            );
            return auth;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Zenith',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}

/// Redirects to Login or Home based on auth state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}