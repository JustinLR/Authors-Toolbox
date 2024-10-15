class Book {
  String title;
  String filePath;
  String? coverImagePath; // Field to store the cover image path
  String series;
  String? description;
  String? url; // Add the optional URL field

  Book({
    required this.title,
    required this.filePath,
    this.coverImagePath,
    required this.series,
    this.description,
    this.url, // Initialize the URL as optional
  });

  // Create a Book object from JSON
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      title: json['title'],
      filePath: json['filePath'],
      coverImagePath:
          json['coverImagePath'] ?? '', // Default to empty string if no cover
      series: json['series'],
      description: json['description'], // Optional description
      url: json['url'], // Optional URL
    );
  }

  // Convert a Book object to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'filePath': filePath,
      'coverImagePath': coverImagePath,
      'series': series,
      'description': description,
      'url': url, // Include URL in JSON
    };
  }
}
