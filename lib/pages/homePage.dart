import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tugasakhirprak1/pages/provider/language_provider.dart';
import 'package:tugasakhirprak1/pages/detail.dart';
import 'package:tugasakhirprak1/pages/loginPage.dart';
import 'package:tugasakhirprak1/pages/bookmark.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:translator/translator.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final String _apiKey = '48f18fea23ad4a8aab46d41fce62102d';
  final String _apiUrl = 'https://newsapi.org/v2/everything';
  final translator = GoogleTranslator();
  List<Map<String, dynamic>> _articles = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _currentCategory = 'general';
  int _currentPage = 1;
  String _currentQuery = '';
  bool _hasMoreData = true;

  final List<String> categories = [
    'general',
    'business',
    'technology',
    'sports',
    'entertainment',
    'health',
  ];

  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _fetchNews(String query, {bool isNewSearch = true}) async {
    if (isNewSearch) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _currentQuery = query;
        _hasMoreData = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    final url = Uri.parse(
        '$_apiUrl?q=${query.isEmpty ? _currentCategory : query}&apiKey=$_apiKey&page=$_currentPage&pageSize=10');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newArticles = List<Map<String, dynamic>>.from(data['articles']);

        if (mounted) {
          setState(() {
            if (isNewSearch) {
              _articles = newArticles;
            } else {
              _articles.addAll(newArticles);
            }

            _hasMoreData = newArticles.length == 10;

            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      } else {
        _handleError('Error fetching news');
      }
    } catch (e) {
      _handleError('Network error');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadMore() async {
    if (!_isLoadingMore && _hasMoreData) {
      _currentPage++;
      await _fetchNews(_currentQuery, isNewSearch: false);
    }
  }

  Future<String> _translate(String text) async {
    final languageCode =
        Provider.of<LanguageProvider>(context, listen: false).languageCode;
    final translation = await translator.translate(text, to: languageCode);
    return translation.text;
  }

  @override
  void initState() {
    super.initState();
    _fetchNews(_currentCategory);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'News App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NewsSearchDelegate(searchNews: _fetchNews),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              languageProvider.setLanguage(value);
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
                PopupMenuItem(
                  value: 'id',
                  child: Text('Bahasa Indonesia'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategorySelector(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await _fetchNews(_currentCategory);
                    },
                    child: ListView.builder(
                      itemCount: _articles.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _articles.length) {
                          return _buildLoadMoreButton();
                        }
                        return FutureBuilder<String>(
                          future: _translate(_articles[index]['title'] ?? ''),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            return _buildNewsCard(
                              _articles[index],
                              translatedTitle: snapshot.data ?? '',
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: _currentCategory == categories[index]
                    ? Colors.white
                    : Colors.black87,
                backgroundColor: _currentCategory == categories[index]
                    ? Color(0xFF4CAF50)
                    : Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                setState(() {
                  _currentCategory = categories[index];
                });
                _fetchNews(categories[index]);
              },
              child: Text(
                categories[index].toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article,
      {String translatedTitle = ''}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailPage(article: article),
            ),
          );
        },
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article['urlToImage'] != null)
                CachedNetworkImage(
                  imageUrl: article['urlToImage'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  translatedTitle.isEmpty ? article['title'] : translatedTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (_isLoadingMore) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_hasMoreData) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _loadMore,
            child: Text('Load More News'),
          ),
        ),
      );
    } else {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No more news available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'News App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.bookmark),
            title: Text('Bookmarks'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookmarkPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class NewsSearchDelegate extends SearchDelegate {
  final Function(String) searchNews;

  NewsSearchDelegate({required this.searchNews});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text('Enter a search term to find news.'),
      );
    }

    return FutureBuilder(
      future: _searchNews(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(
            child: Text(
              'No results found for "$query".',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final articles = snapshot.data as List<Map<String, dynamic>>;

        return ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsDetailPage(article: article),
                  ),
                );
              },
              title: Text(
                article['title'] ?? 'No Title',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                article['source']['name'] ?? 'Unknown Source',
                style: TextStyle(color: Colors.grey[600]),
              ),
              leading: article['urlToImage'] != null
                  ? CachedNetworkImage(
                      imageUrl: article['urlToImage'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  : Icon(Icons.broken_image, size: 50, color: Colors.grey),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text('Search for news articles.'),
      );
    }

    return FutureBuilder(
      future: _searchNews(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(
            child: Text(
              'No suggestions found for "$query".',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final articles = snapshot.data as List<Map<String, dynamic>>;

        return ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return ListTile(
              onTap: () {
                query = article['title'];
                showResults(context);
              },
              title: Text(
                article['title'] ?? 'No Title',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _searchNews(String query) async {
    final String apiKey = 'abbe40a8f28e4cc0a75f74f5af49b9f5';
    final String apiUrl = 'https://newsapi.org/v2/everything';
    final url = Uri.parse('$apiUrl?q=$query&apiKey=$apiKey&pageSize=10');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['articles']);
      } else {
        throw Exception('Failed to fetch results');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
