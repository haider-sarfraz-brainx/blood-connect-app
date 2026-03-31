import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/view_constants.dart';
import '../../data/managers/local/world_places_manager.dart';
import '../../data/models/world_places/city_model.dart';
import '../../data/models/world_places/country_model.dart';
import '../../injection_container.dart';
import '../custom_text.dart';
import '../custom_text_field.dart';

class LocationSelectionBottomSheet extends StatefulWidget {
  final String? initialCountry;
  final String? initialCity;
  final bool selectOnlyCountry;

  const LocationSelectionBottomSheet({
    super.key,
    this.initialCountry,
    this.initialCity,
    this.selectOnlyCountry = false,
  });

  static Future<Map<String, String?>?> show({
    required BuildContext context,
    String? initialCountry,
    String? initialCity,
    bool selectOnlyCountry = false,
  }) {
    return showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectionBottomSheet(
        initialCountry: initialCountry,
        initialCity: initialCity,
        selectOnlyCountry: selectOnlyCountry,
      ),
    );
  }

  @override
  State<LocationSelectionBottomSheet> createState() => _LocationSelectionBottomSheetState();
}

class _LocationSelectionBottomSheetState extends State<LocationSelectionBottomSheet> {
  final _searchController = TextEditingController();
  final _worldPlacesManager = sl<WorldPlacesManager>();
  
  CountryModel? _selectedCountry;
  CityModel? _selectedCity;
  bool _isSelectingCity = false;
  List<dynamic> _filteredList = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeData() async {
    if (_worldPlacesManager.isLoading) return;
    if (_worldPlacesManager.countries.isEmpty) {
      await _worldPlacesManager.load();
    }
    
    if (widget.initialCountry != null) {
      _selectedCountry = _worldPlacesManager.countries.firstWhere(
        (c) => c.name == widget.initialCountry,
        orElse: () => _worldPlacesManager.countries.first,
      );
      if (widget.initialCity != null && !widget.selectOnlyCountry) {
        _selectedCity = _selectedCountry?.cities.firstWhere(
          (c) => c.name == widget.initialCity,
          orElse: () => _selectedCountry!.cities.first,
        );
      }
    }

    _updateFilteredList();
    if (mounted) setState(() {});
  }

  void _onSearchChanged() {
    _updateFilteredList();
    setState(() {});
  }

  void _updateFilteredList() {
    final query = _searchController.text.toLowerCase();
    if (_isSelectingCity && _selectedCountry != null) {
      _filteredList = _selectedCountry!.cities
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
    } else {
      _filteredList = _worldPlacesManager.countries
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    
    return Container(
      height: mediaQuery.size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (_isSelectingCity)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      setState(() {
                        _isSelectingCity = false;
                        _searchController.clear();
                        _updateFilteredList();
                      });
                    },
                  ),
                Expanded(
                  child: CustomText(
                    text: _isSelectingCity ? 'Select City' : 'Select Country',
                    size: 20,
                    weight: FontWeight.bold,
                    translate: false,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomTextField(
              hintText: _isSelectingCity ? 'Search City' : 'Search Country',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          if (_worldPlacesManager.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _filteredList.length,
                itemBuilder: (context, index) {
                  final item = _filteredList[index];
                  final isSelected = (_isSelectingCity)
                      ? _selectedCity?.name == item.name
                      : _selectedCountry?.name == item.name;

                  return ListTile(
                    title: Text(item.name),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.red) : null,
                    onTap: () {
                      if (_isSelectingCity) {
                        Navigator.pop(context, <String, String?>{
                          'country': _selectedCountry?.name,
                          'city': item.name,
                        });
                      } else {
                        if (widget.selectOnlyCountry) {
                          Navigator.pop(context, <String, String?>{
                            'country': item.name,
                            'city': null,
                          });
                        } else {
                          setState(() {
                            _selectedCountry = item;
                            _isSelectingCity = true;
                            _searchController.clear();
                            _updateFilteredList();
                          });
                        }
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
