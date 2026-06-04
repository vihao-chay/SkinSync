import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/auth/supabase_oauth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureSupabase();
  runApp(const SkinSyncApp());
}
