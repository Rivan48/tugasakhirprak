import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'News Search',
      home: NewsSearchPage(),
    );
  }
}

class NewsSearchPage extends StatefulWidget {
  const NewsSearchPage({super.key});

  @override
  _NewsSearchPageState createState() => _NewsSearchPageState();
}

class _NewsSearchPageState extends State<NewsSearchPage> {
  final String _apiKey = 'abbe40a8f28e4cc0a75f74f5af49b9f5';
  final String _apiUrl = 'https://newsapi.org/v2/everything';

  List<Map<String, dynamic>> _articles = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNews('');
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onSubmitted: (value) {
            _fetchNews(value);
          },
          decoration: InputDecoration(
            hintText: 'Search news...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                _fetchNews(_searchController.text);
              },
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return ListTile(
            leading: article['urlToImage'] != null
                ? Image.network(article['urlToImage'])
                : const SizedBox.shrink(),
            title: Text(article['title']),
            subtitle: Text(article['description']),
          );
        },
      ),
    );
  }
}
