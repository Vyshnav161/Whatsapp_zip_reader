import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/whatsapp_zip_provider.dart';
import '../utils/theme_utils.dart';
import 'main_screen.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({Key? key}) : super(key: key);

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Request permissions when the screen loads
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final provider = Provider.of<WhatsappZipProvider>(context, listen: false);
    await provider.requestPermissions();
  }

  Future<void> _importFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = Provider.of<WhatsappZipProvider>(context, listen: false);
      
      // Check if we have permission
      if (!provider.hasPermission) {
        final hasPermission = await provider.requestPermissions();
        if (!hasPermission) {
          setState(() {
            _errorMessage = 'Storage permission is required to import ZIP files';
            _isLoading = false;
          });
          return;
        }
      }
      
      // Pick and process ZIP file
      final success = await provider.pickAndProcessZip();
      
      if (success) {
        // Navigate to main screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else if (provider.errorMessage != null) {
        setState(() {
          _errorMessage = provider.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // WhatsApp-like icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: WhatsAppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 32),
              
              // App title
              const Text(
                'WhatsApp ZIP Viewer',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: WhatsAppTheme.primaryDarkColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // App description
              const Text(
                'Import your WhatsApp chat export ZIP file to view chats and media',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: WhatsAppTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 48),
              
              // Import button
              ElevatedButton(
                onPressed: _isLoading ? null : _importFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WhatsAppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_upload),
                          SizedBox(width: 8),
                          Text(
                            'Import File',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
              ),
              
              // Error message
              if (_errorMessage != null) ...[  
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              
              // Permission status from provider
              Consumer<WhatsappZipProvider>(
                builder: (context, provider, child) {
                  if (!provider.hasPermission) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        'Storage permission is required',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}