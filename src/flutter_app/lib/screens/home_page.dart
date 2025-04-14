
import 'package:flutter/material.dart';
import 'package:credit_card_savvy/models/credit_card.dart';
import 'package:credit_card_savvy/services/card_storage.dart';
import 'package:credit_card_savvy/services/github_sync.dart';
import 'package:credit_card_savvy/screens/card_form_page.dart';
import 'package:credit_card_savvy/screens/card_detail_page.dart';
import 'package:credit_card_savvy/widgets/best_card_widget.dart';
import 'package:credit_card_savvy/widgets/credit_card_item.dart';
import 'package:credit_card_savvy/utils/card_recommendation.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CreditCard> _cards = [];
  bool _isLoading = true;
  bool _showGitHubSetup = false;
  final GitHubSync _githubSync = GitHubSync();
  
  @override
  void initState() {
    super.initState();
    _loadCards();
    _checkGitHubStatus();
  }

  Future<void> _checkGitHubStatus() async {
    final isAuthenticated = await _githubSync.isAuthenticated();
    setState(() {
      _showGitHubSetup = !isAuthenticated;
    });
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    
    // First try to load from GitHub if authenticated
    if (await _githubSync.isAuthenticated()) {
      final githubData = await _githubSync.loadDataFromGitHub();
      if (githubData != null) {
        try {
          final List<dynamic> decoded = jsonDecode(githubData);
          final githubCards = decoded.map((item) => CreditCard.fromJson(item)).toList();
          
          // Save the GitHub data to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(CardStorage.storageKey, githubData);
          
          setState(() {
            _cards = githubCards;
            _isLoading = false;
          });
          return;
        } catch (e) {
          print('Error parsing GitHub data: $e');
        }
      }
    }
    
    // Fallback to local storage
    final cards = await CardStorage.getCards();
    if (mounted) {
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    }
  }

  Future<void> _showGitHubLoginDialog() async {
    final tokenController = TextEditingController();
    final usernameController = TextEditingController();
    final repoController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub Integration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sync your credit card data with a GitHub repository.\n\n'
                'You\'ll need a personal access token with repo scope.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final url = Uri.parse('https://github.com/settings/tokens/new');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Create GitHub Token'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(
                  labelText: 'GitHub Token',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'GitHub Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: repoController,
                decoration: const InputDecoration(
                  labelText: 'Repository Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tokenController.text.isNotEmpty && 
                  usernameController.text.isNotEmpty && 
                  repoController.text.isNotEmpty) {
                await _githubSync.saveCredentials(
                  tokenController.text, 
                  usernameController.text, 
                  repoController.text
                );
                
                // Test the connection and sync initial data
                try {
                  final cards = await CardStorage.getCards();
                  final encoded = jsonEncode(cards.map((card) => card.toJson()).toList());
                  await _githubSync.syncData(encoded);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('GitHub integration successful')),
                  );
                  
                  setState(() {
                    _showGitHubSetup = false;
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('GitHub integration failed: $e')),
                  );
                }
                
                Navigator.of(context).pop();
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Card Savvy'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              if (await _githubSync.isAuthenticated()) {
                await _loadCards();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data synchronized with GitHub')),
                );
              } else {
                _showGitHubLoginDialog();
              }
            },
            tooltip: 'Sync with GitHub',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'github_setup') {
                _showGitHubLoginDialog();
              } else if (value == 'github_disconnect') {
                await _githubSync.clearCredentials();
                setState(() {
                  _showGitHubSetup = true;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('GitHub disconnected')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'github_setup',
                child: Text('Setup GitHub Sync'),
              ),
              const PopupMenuItem(
                value: 'github_disconnect',
                child: Text('Disconnect GitHub'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CardFormPage()),
          );
          _loadCards();
        },
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.credit_card, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No credit cards yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add a card to get started',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CardFormPage()),
                              );
                              _loadCards();
                            },
                            child: const Text('Add Card'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCards,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Best Card Recommendation
                            if (_cards.isNotEmpty) 
                              BestCardWidget(bestCard: getBestCard(_cards)),
                            
                            const SizedBox(height: 24),
                            const Text(
                              'Your Cards',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Card List
                            ..._cards.map((card) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CreditCardItem(
                                card: card,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CardDetailPage(card: card),
                                    ),
                                  );
                                  _loadCards();
                                },
                              ),
                            )).toList(),
                          ],
                        ),
                      ),
                    ),
                    
          // GitHub setup reminder banner
          if (_showGitHubSetup)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.blue.withOpacity(0.9),
                child: Row(
                  children: [
                    const Icon(Icons.sync, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sync your data with GitHub',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: _showGitHubLoginDialog,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: const Text('Setup'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _showGitHubSetup = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
