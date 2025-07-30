import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/whatsapp_zip_provider.dart';
import 'screens/entry_screen.dart';
import 'utils/theme_utils.dart';

void main() async {
  // Ensure Flutter is initialized before using platform channels
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WhatsappZipProvider(),
      child: MaterialApp(
        title: 'WhatsApp ZIP Viewer',
        theme: WhatsAppTheme.theme,
        home: const EntryScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
