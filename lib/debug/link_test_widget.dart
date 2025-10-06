import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A simple debug widget to test URL launching functionality
class LinkTestWidget extends StatelessWidget {
  const LinkTestWidget({Key? key}) : super(key: key);

  Future<void> _testLaunchUrl(String url, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Format URL
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }
      
      final Uri uri = Uri.parse(formattedUrl);
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Attempting to launch: $formattedUrl'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Test canLaunchUrl first
      final bool canLaunch = await canLaunchUrl(uri);
      print('canLaunchUrl($formattedUrl): $canLaunch');
      
      if (canLaunch) {
        final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('launchUrl result: $launched');
        
        if (!launched) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Launch returned false'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('canLaunchUrl returned false'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error launching URL: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test URL Launching',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _testLaunchUrl('https://www.google.com', context),
              child: const Text('Test: https://www.google.com'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _testLaunchUrl('www.google.com', context),
              child: const Text('Test: www.google.com'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _testLaunchUrl('google.com', context),
              child: const Text('Test: google.com'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _testLaunchUrl('http://www.google.com', context),
              child: const Text('Test: http://www.google.com'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Check the console output and SnackBar messages for debugging info.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}