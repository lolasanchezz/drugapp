import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
        Uri.parse('https://api.fda.gov/drug/label.json?search=drug_interactions:${Uri.encodeComponent(drugName)}&limit=10'),
      );

      if (response.statusCode != 200) {
        throw Exception('Network response was not ok');
      }

      final data = json.decode(response.body);
      setState(() {
        _results = data['results'] ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drug Interaction Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter drug name',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _handleSearch,
              child: Text(_loading ? 'Searching...' : 'Search'),
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
                  final brandNames = result['openfda']['brand_name']?.join(', ') ?? 'No brand name available';
                  final interactions = result['drug_interaction']?.join(', ') ?? 'No interactions found';
                  return ListTile(
                    title: Text(brandNames),
                    subtitle: Text(interactions),
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
