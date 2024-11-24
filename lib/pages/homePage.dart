import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tugasakhirprak1/pages/detail.dart';
import 'package:tugasakhirprak1/pages/loginPage.dart';
import 'package:tugasakhirprak1/pages/bookmark.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final String _apiKey = 'abbe40a8f28e4cc0a75f74f5af49b9f5';
  final String _apiUrl = 'https://newsapi.org/v2/everything';

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

        setState(() {
          if (isNewSearch) {
            _articles = newArticles;
          } else {
            _articles.addAll(newArticles);
          }

          // Check if we have more data to load
          _hasMoreData = newArticles.length == 10;

          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching news')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error')),
      );
    }
  }

  Future<void> _loadMore() async {
    if (!_isLoadingMore && _hasMoreData) {
      _currentPage++;
      await _fetchNews(_currentQuery, isNewSearch: false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNews(_currentCategory);
  }

  @override
  Widget build(BuildContext context) {
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
                delegate: NewsSearchDelegate(
                  searchNews: _fetchNews,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
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
          ),
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

                        final article = _articles[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      NewsDetailPage(article: article),
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
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        article['urlToImage'],
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            height: 200,
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.error_outline,
                                              color: Colors.grey[500],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.newspaper,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                article['source']['name'] ?? '',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (article['publishedAt'] != null)
                                              Text(
                                                timeago.format(
                                                  DateTime.parse(
                                                    article['publishedAt'],
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          article['title'] ?? '',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          article['description'] ?? '',
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      drawer: Drawer(
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
    if (query.isNotEmpty) {
      searchNews(query);
    }
    close(context, null);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
