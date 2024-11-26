import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';
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
  final translator = GoogleTranslator();
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
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

    // Jika komentar adalah reply, kirimkan notifikasi kepada pemilik komentar
    if (parentCommentId != null) {
      final parentCommentDoc = await _firestore
          .collection('articles')
          .doc(widget.article['title'])
          .collection('comments')
          .doc(parentCommentId)
          .get();

      if (parentCommentDoc.exists) {
        final parentComment = parentCommentDoc.data()!;
        final parentUsername = parentComment['username'] ?? 'Someone';

        // Tampilkan notifikasi
        showReplyNotification(parentUsername, commentText);
      }
    }

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

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open article: $e')),
      );
    }
  }

  void showReplyNotification(String username, String comment) {
    print('Sending notification: $username replied: $comment'); // Tambahkan log
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'comments_channel',
        title: 'You have a new reply!',
        body: '$username replied: $comment',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Widget _buildReplies(String commentId) {
    final _replyController = TextEditingController();
    int commentsLimit = 3;

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kolom untuk komentar baru di atas replies
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      filled: true,
                      fillColor: Color(0xFF4CAF50),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {
                    _postComment(_replyController.text,
                        parentCommentId: commentId);
                    _replyController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                  child: Text('Reply'),
                ),
              ],
            ),
            SizedBox(height: 10),
            // List replies
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('articles')
                  .doc(widget.article['title'])
                  .collection('comments')
                  .doc(commentId)
                  .collection('replies')
                  .orderBy('timestamp', descending: true)
                  .limit(commentsLimit)
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
                        final reply =
                            replies[index].data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                          child: ListTile(
                            title: Text(
                              reply['username'] ?? 'Anonymous',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                            subtitle: Text(
                              reply['comment'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                            trailing: Text(
                              _formatTimestamp(reply['timestamp']),
                              style: TextStyle(
                                  fontSize: 10, color: Colors.black45),
                            ),
                          ),
                        );
                      },
                    ),
                    if (snapshot.data!.docs.length >= commentsLimit)
                      TextButton(
                        onPressed: () {
                          // Perbarui hanya bagian ini dengan StatefulBuilder
                          setInnerState(() {
                            commentsLimit += 3;
                          });
                        },
                        child: Text(
                          "Load More Replies",
                          style: TextStyle(color: Color(0xFF4CAF50)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('News Details'),
        backgroundColor: Color(0xFF4CAF50),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.black : Colors.white,
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
                    translations[0],
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    translations[1],
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    translations[2],
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: () => widget.article['url'] != null
                        ? _launchURL(widget.article['url'])
                        : ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Article URL not available'),
                              backgroundColor: Colors.red,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text(
                      'Read Full Article',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            filled: true,
                            fillColor: Color(0xFF4CAF50),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: () => _postComment(_commentController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4CAF50),
                        ),
                        child: Text('Post'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
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
                          style: TextStyle(color: Colors.black),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment =
                              comments[index].data() as Map<String, dynamic>;
                          final commentId = comments[index].id;

                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  title: Text(
                                    comment['username'] ?? 'Anonymous',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  subtitle: Text(
                                    comment['comment'] ?? '',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black),
                                  ),
                                  trailing: Text(
                                    _formatTimestamp(comment['timestamp']),
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.black45),
                                  ),
                                ),
                                _buildReplies(commentId),
                              ],
                            ),
                          );
                        },
                      );
                    },
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
