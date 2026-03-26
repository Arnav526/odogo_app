import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import 'package:odogo_app/controllers/user_controller.dart';
import 'package:odogo_app/data/iitk_dropoff_locations.dart';

class HomeAddressEditScreen extends ConsumerStatefulWidget {
  const HomeAddressEditScreen({super.key});
  @override
  ConsumerState<HomeAddressEditScreen> createState() =>
      _HomeAddressEditScreenState();
}

class _HomeAddressEditScreenState extends ConsumerState<HomeAddressEditScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null && user.home != null) {
      _addressController.text = user.home!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a home address first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await ref
        .read(userControllerProvider.notifier)
        .updateHome(_addressController.text.trim());

    if (!mounted) return;

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Home address updated!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _openAddressSelector() async {
    String localSearchText = '';

    final selected = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            // Reusing alias filtering logic
            List<DropoffLocation> sheetFiltered = localSearchText.isEmpty
                ? iitkDropoffLocations
                : iitkDropoffLocations
                      .where(
                        (loc) =>
                            loc.name.toLowerCase().contains(
                              localSearchText.toLowerCase(),
                            ) ||
                            loc.matches(localSearchText),
                      )
                      .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.65,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Text(
                            'Set Home Address',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: TextField(
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search hostel or hall...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.black54,
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                              ),
                            ),
                            onChanged: (val) {
                              setSheetState(() => localSearchText = val);
                            },
                          ),
                        ),

                        if (localSearchText.isNotEmpty && sheetFiltered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No locations found matching "$localSearchText"',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),

                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: sheetFiltered.length,
                            itemBuilder: (context, index) {
                              final location = sheetFiltered[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.home_outlined,
                                  color: Colors.black54,
                                ),
                                title: Text(location.name),
                                onTap: () =>
                                    Navigator.pop(sheetContext, location),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      if (selected is String) {
        _addressController.text = selected;
      } else if (selected is DropoffLocation) {
        _addressController.text = selected.name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          user?.name ?? 'Profile',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.home_outlined, size: 32, color: Colors.black),
                  SizedBox(width: 12),
                  Text(
                    'Home Address',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              GestureDetector(
                onTap: _openAddressSelector,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _addressController.text.isEmpty
                              ? 'Search campus locations...'
                              : _addressController.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: _addressController.text.isEmpty
                                ? Colors.grey[600]
                                : Colors.black87,
                            fontWeight: _addressController.text.isEmpty
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
