import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tugasakhirprak1/pages/detail.dart';
import 'package:tugasakhirprak1/pages/loginPage.dart';
import 'package:tugasakhirprak1/pages/bookmark.dart'; // Tambahkan import untuk BookmarkPage

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final String _apiKey = 'abbe40a8f28e4cc0a75f74f5af49b9f5';
  final String _apiUrl = 'https://newsapi.org/v2/everything';

  List<Map<String, dynamic>> _articles = [];
  TextEditingController _searchController = TextEditingController();

  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _fetchNews(String query) async {
    final url = Uri.parse('$_apiUrl?q=$query&apiKey=$_apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _articles = List<Map<String, dynamic>>.from(data['articles']);
      });
    } else {
      // Handle error
      print('Error fetching news: ${response.statusCode}');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNews('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onSubmitted: (value) {
            _fetchNews(value);
          },
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
          decoration: InputDecoration(
            hintText: 'Search news...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16.0,
            ),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                _fetchNews(_searchController.text);
              },
            ),
          ),
        ),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsDetailPage(article: article),
                ),
              );
            },
            child: Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListTile(
                leading: article['urlToImage'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          article['urlToImage'],
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      )
                    : SizedBox.shrink(),
                title: Text(
                  article['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                subtitle: Text(
                  article['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF4CAF50),
              ),
              child: Text(
                'News App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
              },
            ),
            // Tambahkan menu Bookmarks
            ListTile(
              leading: Icon(Icons.bookmark),
              title: Text('Bookmarks'),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
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
