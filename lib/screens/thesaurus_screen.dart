import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class ThesaurusScreen extends StatefulWidget {
  @override
  _ThesaurusScreenState createState() => _ThesaurusScreenState();
}

class _ThesaurusScreenState extends State<ThesaurusScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _synonyms = [];
  List<String> _antonyms = [];
  String _definition = '';
  bool _loading = false;
  String _errorMessage = '';
  String _apiKey = '307a0a28-8259-4b46-afe5-467f5dd1841b';
  /////////////////////////////
  // Thesaurus API key //
  /////////////////////////////

  List<Map<String, String>> _wikiResults = [];

  //////////////////////////////
  // Function to search for word details //
  //////////////////////////////
  Future<void> _searchWordDetails(String word) async {
    setState(() {
      _loading = true;
      _errorMessage = '';
      _wikiResults.clear();
    });

    final thesaurusApiUrl =
        'https://dictionaryapi.com/api/v3/references/thesaurus/json/$word?key=$_apiKey';
    final wikiApiUrl =
        'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=$word&format=json&utf8=&srlimit=3';

    try {
      final thesaurusResponse = await http.get(Uri.parse(thesaurusApiUrl));
      final wikiResponse = await http.get(Uri.parse(wikiApiUrl));

      if (thesaurusResponse.statusCode == 200) {
        final thesaurusData = json.decode(thesaurusResponse.body);
        if (thesaurusData is List &&
            thesaurusData.isNotEmpty &&
            thesaurusData[0] is Map) {
          final entry = thesaurusData[0];
          List<String> syns = [];
          List<String> ants = [];
          String def = 'No definition found';

          if (entry.containsKey('meta') && entry['meta'].containsKey('syns')) {
            syns = (entry['meta']['syns'] as List)
                .expand((item) => item as List)
                .cast<String>()
                .toList();
          }
          if (entry.containsKey('meta') && entry['meta'].containsKey('ants')) {
            ants = (entry['meta']['ants'] as List)
                .expand((item) => item as List)
                .cast<String>()
                .toList();
          }
          if (entry.containsKey('shortdef') && entry['shortdef'] is List) {
            def = entry['shortdef'].isNotEmpty ? entry['shortdef'][0] : def;
          }

          setState(() {
            _synonyms = syns;
            _antonyms = ants;
            _definition = def;
            _loading = false;
          });
        }
      }

      if (wikiResponse.statusCode == 200) {
        final wikiData = json.decode(wikiResponse.body);
        final searchResults = wikiData['query']['search'] as List;

        setState(() {
          _wikiResults = searchResults.map((result) {
            final cleanedSnippet = _cleanHtmlTags(result['snippet'].toString());
            return {
              'title': result['title'].toString(),
              'snippet': cleanedSnippet,
              'pageUrl':
                  'https://en.wikipedia.org/wiki/${result['title'].toString().replaceAll(' ', '_')}',
            };
          }).toList();
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch Wikipedia data';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
        _loading = false;
      });
    }
  }

  /////////////////////////////
  // Clean HTML tags from Wikipedia snippets //
  /////////////////////////////
  String _cleanHtmlTags(String text) {
    final RegExp spanTagRegExp =
        RegExp(r'<span class="searchmatch">(.*?)<\/span>');
    return text.replaceAllMapped(
        spanTagRegExp, (match) => match.group(1) ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thesaurus'),
      ),
      drawer: AppNavigationDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a word to find its details:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            /////////////////////////////
            // Text input for word search //
            /////////////////////////////
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search word',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                _searchWordDetails(value);
              },
            ),
            SizedBox(height: 20),
            /////////////////////////
            // Search button //
            /////////////////////////
            ElevatedButton(
              onPressed: () {
                _searchWordDetails(_controller.text);
              },
              child: Text('Search'),
            ),
            SizedBox(height: 20),
            if (_loading)
              Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Center(
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              /////////////////////////////
              // Definition Section //
              /////////////////////////////
              Text(
                'Definition:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              SelectableText(
                _definition,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              /////////////////////////////
              // Synonyms and Antonyms side by side //
              /////////////////////////////
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Synonyms:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 150,
                            child: _synonyms.isNotEmpty
                                ? ListView.builder(
                                    itemCount: _synonyms.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                          title:
                                              SelectableText(_synonyms[index]));
                                    },
                                  )
                                : Center(child: Text('No synonyms found')),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Antonyms:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 150,
                            child: _antonyms.isNotEmpty
                                ? ListView.builder(
                                    itemCount: _antonyms.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                          title:
                                              SelectableText(_antonyms[index]));
                                    },
                                  )
                                : Center(child: Text('No antonyms found')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ///////////////////////////////
              // Related Wikipedia results //
              ///////////////////////////////
              Text(
                'Related Wikipedia Results:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: _wikiResults.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: _wikiResults.length,
                        itemBuilder: (context, index) {
                          final result = _wikiResults[index];
                          return ListTile(
                            title: Text(result['title']!),
                            subtitle: Text(result['snippet']!),
                            onTap: () => _launchURL(result['pageUrl']!),
                          );
                        },
                      )
                    : Center(child: Text('No related Wikipedia results found')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /////////////////////////
  // Function to launch a URL //
  /////////////////////////
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }
}
