import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_gemini/google_gemini.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

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
        //put limit as 10 here - we can change later
        Uri.parse("https://api.fda.gov/drug/label.json?search=drug_interactions:${Uri.encodeComponent(drugName)}&limit=50")
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
Future<void> _gemSummary(description, index, drug) async {

print(description);

final gemini = GoogleGemini(
  apiKey: "AIzaSyClxB5j9KUQpD0ottj97ZLPmCxbqoErd4E"
);

final geminiResponse = await gemini.generateFromText(
  "generate a summary of the description i give you about the interaction between two drugs. make sure to not use any characters or ANY formatting (like bolding with *, - points, etc) that interfere with formatting, and make it addressable to a average, causual NON-SCIENTIFIC user who cares about the drug interactions. make it SUPER succint and relate it to the drug, $drug. the description: $description" 
   )

      .then((value) => setState(() {
       
        var newVal = _results;
        newVal[index]['drug_interactions'] = value.text;
        print(value.text.runtimeType);
       _results = newVal;
      }));
      
     // print(geminiResponse.text);
      


  

      


  }  
  

 void _toggleDropdown(int index) {
    setState(() {
      _isExpanded[index] = !_isExpanded[index]; // Toggle expansion
    });
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
                  print(result['drug_interactions'].runtimeType);
                  final brandNames = result['spl_product_data_elements']?.join(', ') ?? 'No brand name available';
                  final interactions = (result['drug_interactions'] is List) ? result['drug_interactions']?.join(', ') ?? 'No interactions found': result['drug_interactions']?.toString() ?? 'No interactions found';

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                           title: Text(brandNames),

                           trailing: Icon(
                            _isExpanded[index] ? Icons.expand_less : Icons.expand_more
                           ),
                          onTap: () => _toggleDropdown(index),
                        ),
                          if (_isExpanded[index]) 
                            Padding(padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _gemSummary(interactions, index,  _controller.text.trim()),
                                  child: Text("summary")
                                 ),
                              Text(interactions)
                            ],)
                            )
                          
                        
                      ],
                    )
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
