import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'news_detail_screen.dart';
import 'models/news_article.dart';

class NewsfeedScreen extends StatefulWidget {
  @override
  _NewsfeedScreenState createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends State<NewsfeedScreen> {
  final String apiKey = dotenv.env['NEWSAPI_KEY'] ?? '';
  List<Article> _articles = [];
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  int? _totalResults;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _loadNewsFromCache();
    _fetchNews();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchNews();
    }
  }

  Future<void> _fetchNews() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    final String keywords =
        'stocks OR stock OR crypto OR cryptocurrency OR finance OR economy OR investment OR company';
    final String encodedKeywords = Uri.encodeComponent(keywords);
    final String url =
        'https://newsapi.org/v2/everything?q=$encodedKeywords&language=en&pageSize=$_pageSize&page=$_currentPage&sortBy=publishedAt&apiKey=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (_totalResults == null) {
          _totalResults = data['totalResults'] != null
              ? (data['totalResults'] > 100 ? 100 : data['totalResults'])
              : 100;
        }

        List<dynamic> articlesJson = data['articles'] ?? [];
        print('Parsed Articles JSON: $articlesJson');

        if (articlesJson.isNotEmpty) {
          List<Article> fetchedArticles =
              articlesJson.map((json) => Article.fromJson(json)).toList();

          if (_articles.length + fetchedArticles.length > _totalResults!) {
            int remaining = _totalResults! - _articles.length;
            if (remaining > 0) {
              fetchedArticles = fetchedArticles.sublist(0, remaining);
              _hasMore = false;
            } else {
              _hasMore = false;
              fetchedArticles = [];
            }
          } else {
            if (fetchedArticles.length < _pageSize) {
              _hasMore = false;
            }
          }

          setState(() {
            _currentPage++;
            _articles.addAll(fetchedArticles);
            if (fetchedArticles.length < _pageSize) {
              _hasMore = false;
            }
          });

          _cacheNews(_articles);
        } else {
          setState(() {
            _hasMore = false;
          });
        }
      } else {
        print('Error: Non-200 status code (${response.statusCode})');
        if (response.statusCode == 426) {
          setState(() {
            _hasMore = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching news: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cacheNews(List<Article> articles) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cachedArticles = articles
        .map((article) => json.encode({
              'title': article.title,
              'description': article.description,
              'url': article.url,
              'urlToImage': article.imageUrl,
              'publishedAt': article.publishedAt,
              'source': article.source,
              'content': article.content,
            }))
        .toList();
    await prefs.setStringList('cached_stock_news', cachedArticles);
  }

  Future<void> _loadNewsFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cachedArticles = prefs.getStringList('cached_stock_news');

    if (cachedArticles != null && cachedArticles.isNotEmpty) {
      List<Article> articles = cachedArticles
          .map((articleString) => Article.fromJson(json.decode(articleString)))
          .toList();

      setState(() {
        _articles = articles;
        _hasMore = _articles.length < (_totalResults ?? 100);
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _articles.clear();
      _currentPage = 1;
      _hasMore = true;
      _totalResults = null;
    });
    await _fetchNews();
  }

  Article? get _mainNews {
    if (_articles.isNotEmpty) {
      return _articles[0];
    }
    return null;
  }

  List<Article> get _otherNews {
    if (_articles.length > 1) {
      return _articles.sublist(1);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (_articles.isEmpty && _isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.deepPurple.shade900],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
          ),
        ),
      );
    }

    if (_articles.isEmpty && !_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.deepPurple.shade900],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Center(
            child: Text(
              'No news articles found. Please try again later.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple.shade900],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 70.0),
                if (_mainNews != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewsDetailScreen(),
                                settings: RouteSettings(
                                  arguments: _mainNews,
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: CachedNetworkImage(
                              imageUrl: (_mainNews!.imageUrl.isNotEmpty)
                                  ? _mainNews!.imageUrl
                                  : 'https://via.placeholder.com/400x200.png?text=No+Image',
                              placeholder: (context, url) => Container(
                                height: 200,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: Colors.grey,
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.0),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewsDetailScreen(),
                                settings: RouteSettings(
                                  arguments: _mainNews,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            _mainNews!.title,
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _otherNews.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final article = _otherNews[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewsDetailScreen(),
                              settings: RouteSettings(
                                arguments: article,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: CachedNetworkImage(
                                imageUrl: (article.imageUrl.isNotEmpty)
                                    ? article.imageUrl
                                    : 'https://via.placeholder.com/200x120.png?text=No+Image',
                                placeholder: (context, url) => Container(
                                  height: 120,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 120,
                                  color: Colors.grey,
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              article.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16.0),
                if (_hasMore)
                  ElevatedButton(
                    onPressed: _fetchNews,
                    child: _isLoading
                        ? SizedBox(
                            height: 16.0,
                            width: 16.0,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : Text(
                            'More',
                            style: TextStyle(color: Colors.white),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
