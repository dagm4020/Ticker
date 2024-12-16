class Article {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String publishedAt;
  final String source;
  final String content;
  Article({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
    required this.source,
    required this.content,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    String rawContent = json['content'] ?? '';
    rawContent = rawContent.replaceAll(RegExp(r'\s*\[\+\d+\s*chars\]$'), '');

    String rawDescription = json['description'] ?? '';
    rawDescription =
        rawDescription.replaceAll(RegExp(r'\s*\[\+\d+\s*chars\]$'), '');

    return Article(
      title: json['title'] ?? 'No Title',
      description: rawDescription,
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'] ??
          'https://via.placeholder.com/150', // Default image if none provided
      publishedAt: json['publishedAt'] ?? '',
      source: json['source']['name'] ?? 'Unknown Source',
      content: rawContent,
    );
  }
}
