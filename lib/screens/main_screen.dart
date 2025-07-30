import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/whatsapp_zip_provider.dart';
import '../utils/theme_utils.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/media_item.dart';
import 'entry_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _chatScrollController = ScrollController();
  bool _showScrollToTop = false;
  bool _showScrollToBottom = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add scroll listener to detect when to show scroll buttons
    _chatScrollController.addListener(_updateScrollButtonsVisibility);
  }
  
  // Update the visibility of scroll buttons based on scroll position
  void _updateScrollButtonsVisibility() {
    if (!_chatScrollController.hasClients) return;
    
    setState(() {
      // Show scroll-to-top button when not at the top
      _showScrollToTop = _chatScrollController.offset > 200;
      
      // Show scroll-to-bottom button when not at the bottom
      _showScrollToBottom = _chatScrollController.position.maxScrollExtent - 
                           _chatScrollController.offset > 200;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatScrollController.removeListener(_updateScrollButtonsVisibility);
    _chatScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Show confirmation dialog when back button is pressed
  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('The files will be deleted'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Clear extracted files and return to entry screen
      final provider = Provider.of<WhatsappZipProvider>(context, listen: false);
      await provider.clearExtractedFiles();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const EntryScreen()),
        );
      }
    }

    return false; // Prevent default back button behavior
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        _closeSearch();
                      },
                    ),
                  ),
                  onChanged: (value) {
                    final provider = Provider.of<WhatsappZipProvider>(context, listen: false);
                    provider.searchMessages(value);
                  },
                )
              : const Text('WhatsApp Chat'),
          backgroundColor: WhatsAppTheme.appBarColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_isSearching) {
                _closeSearch();
              } else {
                _onWillPop();
              }
            },
          ),
          actions: [
            if (!_isSearching)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'CHAT'),
              Tab(text: 'MEDIA'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Chat Tab
            _buildChatTab(),
            
            // Media Tab
            _buildMediaTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return Consumer<WhatsappZipProvider>(
      builder: (context, provider, child) {
        final chatMessages = provider.chatMessages;
        
        if (chatMessages.isEmpty) {
          return const Center(
            child: Text('No chat messages found'),
          );
        }
        
        return Stack(
          children: [
            // Background
            Positioned.fill(
              child: ColoredBox(
                color: WhatsAppTheme.backgroundColor,
              ),
            ),
            // SVG Pattern
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/chat_background.svg',
                fit: BoxFit.cover,
              ),
            ),
            // Chat messages with date headers
            Stack(
              children: [
                ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: chatMessages.length,
                  itemBuilder: (context, index) {
                    final currentMessage = chatMessages[index];
                    
                    // Show date header if this is the first message or if the date changed
                    final showDateHeader = index == 0 || 
                      !_isSameDay(chatMessages[index-1].timestamp, currentMessage.timestamp);
                    
                    return Column(
                      children: [
                        if (showDateHeader)
                          _buildDateHeader(currentMessage.timestamp),
                        ChatMessageBubble(message: currentMessage),
                      ],
                    );
                  },
                ),
                
                // Scroll to top button
                if (_showScrollToTop)
                  Positioned(
                    right: 16,
                    top: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: WhatsAppTheme.appBarColor,
                      onPressed: _scrollToTop,
                      child: const Icon(Icons.arrow_upward, color: Colors.white),
                    ),
                  ),
                
                // Scroll to bottom button
                if (_showScrollToBottom)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: WhatsAppTheme.appBarColor,
                      onPressed: _scrollToBottom,
                      child: const Icon(Icons.arrow_downward, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaTab() {
    return Consumer<WhatsappZipProvider>(
      builder: (context, provider, child) {
        final mediaFiles = provider.mediaFiles;
        
        if (mediaFiles.isEmpty) {
          return const Center(
            child: Text('No media files found'),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: mediaFiles.length,
          itemBuilder: (context, index) {
            return MediaItem(mediaFile: mediaFiles[index]);
          },
        );
      },
    );
  }
  
  // Scroll to the top of the chat
  void _scrollToTop() {
    _chatScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
  
  // Scroll to the bottom of the chat
  void _scrollToBottom() {
    _chatScrollController.animateTo(
      _chatScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
  
  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  // Close search and clear filters
  void _closeSearch() {
    setState(() {
      _isSearching = false;
    });
    final provider = Provider.of<WhatsappZipProvider>(context, listen: false);
    provider.clearSearch();
  }
  
  // Build a date header widget
  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      // Format date as DD/MM/YYYY
      dateText = DateFormat('dd/MM/yyyy').format(date);
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            dateText,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}