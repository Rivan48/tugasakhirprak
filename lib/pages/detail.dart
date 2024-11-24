import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailPage extends StatefulWidget {
  final Map<String, dynamic> article;

  NewsDetailPage({required this.article});

  @override
  _NewsDetailPageState createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  void _checkBookmarkStatus() async {
    final userId = _auth.currentUser?.uid;
    final docRef = _firestore
        .collection('bookmarks')
        .doc(userId)
        .collection('articles')
        .doc(widget.article['title']);
    final docSnapshot = await docRef.get();

    if (mounted) {
      setState(() {
        _isBookmarked = docSnapshot.exists;
      });
    }
  }

  void _toggleBookmark() async {
    final userId = _auth.currentUser?.uid;
    final docRef = _firestore
        .collection('bookmarks')
        .doc(userId)
        .collection('articles')
        .doc(widget.article['title']);

    if (_isBookmarked) {
      await docRef.delete();
    } else {
      await docRef.set(widget.article);
    }

    if (mounted) {
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News Details'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.orange : Colors.white,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.article['urlToImage'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    widget.article['urlToImage'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                  ),
                ),
              SizedBox(height: 16.0),
              Text(
                widget.article['title'] ?? 'No Title',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Published: ${widget.article['publishedAt']}',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Flexible(
                    child: Text(
                      'Source: ${widget.article['source']['name']}',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Text(
                widget.article['content']?.contains('[+')
                    ? widget.article['content']!.split('[+')[0] + '...'
                    : widget.article['content'] ?? 'No Content Available.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[300],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20.0),
              if (widget.article['url'] != null)
                ElevatedButton(
                  onPressed: () => _launchURL(widget.article['url']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  child: Text(
                    'Read Full Article',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
