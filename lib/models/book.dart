class Book {
  String title;
  String filePath;
  String url;
  String imageUrl;
  String series;
  String? description; // Add description field

  Book({
    required this.title,
    required this.filePath,
    required this.url,
    required this.series,
    this.imageUrl = '',
    this.description, // Initialize description
  });

  // Update fromJson and toJson if you're using JSON serialization:
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'],
      filePath: json['filePath'],
      url: json['url'],
      series: json['series'],
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'], // Load description from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'filePath': filePath,
      'url': url,
      'series': series,
      'imageUrl': imageUrl,
      'description': description, // Save description to JSON
    };
  }
}
