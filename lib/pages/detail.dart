import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Tambahkan Provider
import 'package:translator/translator.dart'; // Tambahkan Translator
import 'package:tugasakhirprak1/pages/provider/language_provider.dart';
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
  final _commentController = TextEditingController();
  final translator = GoogleTranslator(); // Tambahkan Translator Instance
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

  void _postComment(String commentText, {String? parentCommentId}) async {
    if (commentText.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final commentData = {
      'username': user.email ?? 'Anonymous',
      'comment': commentText.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    final commentCollection = parentCommentId == null
        ? _firestore
        .collection('articles')
        .doc(widget.article['title'])
        .collection('comments')
        : _firestore
        .collection('articles')
        .doc(widget.article['title'])
        .collection('comments')
        .doc(parentCommentId)
        .collection('replies');

    await commentCollection.add(commentData);

    _commentController.clear();
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

  Future<String> _translate(String text) async {
    final languageCode =
        Provider.of<LanguageProvider>(context, listen: false).languageCode;
    final translation = await translator.translate(text, to: languageCode);
    return translation.text;
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final DateTime dateTime = timestamp.toDate();
    final DateFormat formatter = DateFormat('MMM dd, yyyy, hh:mm a');
    return formatter.format(dateTime);
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.tryParse(url) ?? Uri();
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode:
        LaunchMode.externalApplication, // Membuka URL di browser eksternal
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  Widget _buildReplies(String commentId) {
    final _replyController = TextEditingController();
    int commentsLimit = 3; // Batas awal jumlah reply yang ditampilkan

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('articles')
              .doc(widget.article['title'])
              .collection('comments')
              .doc(commentId)
              .collection('replies')
              .orderBy('timestamp', descending: true)
              .limit(commentsLimit) // Batas jumlah reply
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final replies = snapshot.data!.docs;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: replies.length,
                  itemBuilder: (context, index) {
                    final reply = replies[index].data() as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 8.0), // Indentasi kanan
                      child: ListTile(
                        title: Text(
                          reply['username'] ?? 'Anonymous',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12, // Perkecil ukuran teks
                            color: Colors.blue,
                          ),
                        ),
                        subtitle: Text(
                          reply['comment'] ?? '',
                          style: TextStyle(
                            fontSize: 12, // Perkecil ukuran teks
                            color: Colors.grey[300],
                          ),
                        ),
                        trailing: Text(
                          _formatTimestamp(reply['timestamp']),
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ),
                    );
                  },
                ),
                if (snapshot.data!.docs.length >= commentsLimit) // Tombol Load More
                  TextButton(
                    onPressed: () {
                      setState(() {
                        commentsLimit += 3; // Tambah jumlah komentar yang ditampilkan
                      });
                    },
                    child: Text(
                      "Load More Replies",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Write a reply...',
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: () {
                _postComment(_replyController.text, parentCommentId: commentId);
                _replyController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text('Reply'),
            ),
          ],
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageProvider>(context);

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
      body: FutureBuilder(
        future: Future.wait([
          _translate(widget.article['title'] ?? 'No Title'),
          _translate(widget.article['description'] ?? 'No Description'),
          _translate(widget.article['content'] ?? 'No Content'),
        ]),
        builder: (context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading content',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final translations =
              snapshot.data ?? ['No Title', 'No Description', 'No Content'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.article['urlToImage'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: CachedNetworkImage(
                        imageUrl: widget.article['urlToImage'] ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 250,
                        placeholder: (context, url) =>
                            Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.grey[500],
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 16.0),
                  Text(
                    translations[0], // Title yang diterjemahkan
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    translations[1], // Deskripsi yang diterjemahkan
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    translations[2], // Konten yang diterjemahkan
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey[300],
                    ),
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () {
                      _launchURL(widget.article['url']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text('Read Full Article'),
                  ),
                  SizedBox(height: 20.0),
                  Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('articles')
                        .doc(widget.article['title'])
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final comments = snapshot.data!.docs;

                      if (comments.isEmpty) {
                        return Text(
                          'No comments yet. Be the first to comment!',
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index].data() as Map<String, dynamic>;
                          final commentId = comments[index].id;

                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0), // Indentasi kecil untuk komentar utama
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text(
                                    comment['username'] ?? 'Anonymous',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14, // Sedikit lebih besar dari reply
                                      color: Colors.orange,
                                    ),
                                  ),
                                  subtitle: Text(
                                    comment['comment'] ?? '',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                                  ),
                                  trailing: Text(
                                    _formatTimestamp(comment['timestamp']),
                                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                  ),
                                ),
                                _buildReplies(commentId), // Panggil fungsi replies di sini
                              ],
                            ),
                          );
                        },
                      );

                    },
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () => _postComment(_commentController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: Text('Post'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
