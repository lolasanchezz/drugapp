import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_gemini/google_gemini.dart';
import 'package:collection/collection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drug Interaction App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE4D9FF), // Background color
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: const Color(0xFF976CAB), // Button background color
        ),
      ),
      home: const DrugInteractionSearch(),
    );
  }
}

class DrugInteractionSearch extends StatefulWidget {
  const DrugInteractionSearch({super.key});

  @override
  _DrugInteractionSearchState createState() => _DrugInteractionSearchState();
}

class _DrugInteractionSearchState extends State<DrugInteractionSearch> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  String? _error;
  bool _loading = false;
  List<bool> _isExpanded = [];

  Future<void> _handleSearch() async {
    final drugName = _controller.text.trim();
    if (drugName.isEmpty) {
      setState(() {
        _error = 'Please enter a drug name.';
      });
      return;
    }

    setState(() {
      _error = null; // Clear previous errors
      _results = []; // Clear previous results
      _loading = true; // Set loading state
    });

    try {
      final response = await http.get(
        Uri.parse(
          "https://api.fda.gov/drug/label.json?search=drug_interactions:${Uri.encodeComponent(drugName)}&limit=10", // Limit set to 10
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Network response was not ok');
      }

      final data = json.decode(response.body)['results'];

      setState(() {
        _results = data ?? [];
        _isExpanded = List.generate(_results.length, (_) => false);
      });
    } catch (err) {
      setState(() {
        _error = err.toString();
      });
    } finally {
      setState(() {
        _loading = false; // Reset loading state
      });
    }
  }

  Future<void> _gemSummary(description, index, name) async {
    final gemini = GoogleGemini(
      apiKey: "AIzaSyClxB5j9KUQpD0ottj97ZLPmCxbqoErd4E",
    );

    await gemini
        .generateFromText(
          "Prompt: **DO NOT** USE SPECIAL MARKDOWN BOLDING CHARACTERS!!! not even ONE ASTERISK. Summarize the following in less-scientific terms ONLY in how it relates to $name, and mention the max dosage of the two drugs when taken together"
          "$description",
        )
        .then(
          (value) => setState(() {
            var text = value.text.replaceAll(RegExp(r'\*'), '').replaceAll(RegExp(r'\*'), '-');
            _results[index]['drug_interactions'] = text;
          }),
        )
        .catchError((e) => setState(() {
          _results[index]['drug_interactions'] = Text(e);
        }));
  }

  void _toggleDropdown(int index) {
    setState(() {
      _isExpanded[index] = !_isExpanded[index]; // Toggle expansion
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drug Interaction Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter drug name',
                prefixIcon: Icon(Icons.search, color: const Color(0xFF5A3B69)), // Magnifying glass icon
                labelStyle: TextStyle(color: const Color(0xFF5A3B69)), // Label color
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFFE4D9FF), width: 1.0), // Border color when enabled
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: const Color(0xFF5A3B69), width: 2.0), // Border color when focused
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              style: TextStyle(color: const Color(0xFF5A3B69)), // Text color
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _handleSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF976CAB), // Button background color
              ),
              child: Text(_loading ? 'Searching...' : 'Search', style: TextStyle(color: Colors.white)), // Button text color
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  final brandNames =
                      result['spl_product_data_elements']?.join(', ') ??
                      'No brand name available';
                  final interactions =
                      (result['drug_interactions'] is List)
                          ? result['drug_interactions']?.join(', ') ??
                              'No interactions description found'
                          : result['drug_interactions']?.toString() ??
                              'No interactions description found';

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(brandNames, style: TextStyle(color: const Color(0xFF5A3B69))), // Text color
                          trailing: Icon(
                            _isExpanded[index]
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          onTap: () => _toggleDropdown(index),
                        ),
                        if (_isExpanded[index])
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _gemSummary(interactions, index, (_controller.text.trim())),
                                  child: Text("Summary", style: TextStyle(color: Colors.white)), // Button text color
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF976CAB), // Button background color
                                  ),
                                ),
                                Text(interactions, style: TextStyle(color: const Color(0xFF5A3B69))), // Text color
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
