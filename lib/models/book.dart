class Book {
  String title;
  String filePath;
  String url;
  String imageUrl;
  String series;

  Book({
    required this.title,
    required this.filePath,
    required this.url,
    this.imageUrl = '',
    this.series = 'None', // Default to 'None' for individual books
  });

  // Convert a Book object into a Map object for JSON encoding
  Map<String, dynamic> toJson() => {
        'title': title,
        'filePath': filePath,
        'url': url,
        'imageUrl': imageUrl,
        'series': series,
      };

  // Convert a Map object into a Book object for JSON decoding
  factory Book.fromJson(Map<String, dynamic> json) {
    // Ensure the series is valid
    String series =
        json['series']?.isNotEmpty == true ? json['series'] : 'None';
    return Book(
      title: json['title'],
      filePath: json['filePath'],
      url: json['url'],
      imageUrl: json['imageUrl'] ?? '',
      series: series,
    );
  }
}
