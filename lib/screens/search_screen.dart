import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pande_parsi/databases/local_dtb.dart';
import 'package:pande_parsi/models/pand.dart';
import 'package:pande_parsi/widgets/style_pand.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Timer? _debounce;
  final LocalDtb localDtb = LocalDtb.instance;
  List<Pand> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  void _onSearchChanged(String query) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await localDtb.searchPands(query);

    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xfffde8bd),
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'جستجو...',
                  hintTextDirection: TextDirection.rtl,
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontFamily: 'Roya', fontSize: 21),
                ),
                style: TextStyle(fontFamily: 'Roya', fontSize: 21),
                textDirection: TextDirection.rtl,
                onChanged: _onSearchChanged,
                autofocus: true,
              ),
            ),
            Icon(Icons.search_outlined),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _isSearching
                ? Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'جستجو کنید!'
                        : 'این کلمه در پندها پیدا نشد.',
                    textDirection: TextDirection.rtl,
                  ),
                )
                : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (ctx, i) => StylePand(pnd: _searchResults[i]),
                ),
      ),
    );
  }
}
