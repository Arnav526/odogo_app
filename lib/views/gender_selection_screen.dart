import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odogo_app/controllers/auth_controller.dart';
import 'package:odogo_app/controllers/user_controller.dart';

enum Gender { male, female, other, preferNotToSay }

class GenderSelectionScreen extends ConsumerStatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  ConsumerState<GenderSelectionScreen> createState() =>
      _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends ConsumerState<GenderSelectionScreen> {
  Gender? _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // PRE-FILL
    final user = ref.read(currentUserProvider);
    if (user != null) {
      switch (user.gender.toLowerCase()) {
        case 'male':
          _selectedGender = Gender.male;
          break;
        case 'female':
          _selectedGender = Gender.female;
          break;
        case 'other':
          _selectedGender = Gender.other;
          break;
        default:
          _selectedGender = Gender.preferNotToSay;
          break;
      }
    }
  }

  Future<void> _saveGender() async {
    if (_selectedGender == null) return;
    setState(() => _isLoading = true);

    // Map Enum to String for Database
    String genderStr = 'Prefer not to say';
    if (_selectedGender == Gender.male) genderStr = 'Male';
    if (_selectedGender == Gender.female) genderStr = 'Female';
    if (_selectedGender == Gender.other) genderStr = 'Other';

    // Save
    await ref.read(userControllerProvider.notifier).updateGender(genderStr);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gender updated!'),
        backgroundColor: Color(0xFF66D2A3),
      ),
    );
    Navigator.pop(context);
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
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gender',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildRadioTile('Male', Gender.male),
                    _buildRadioTile('Female', Gender.female),
                    _buildRadioTile('Other', Gender.other),
                    _buildRadioTile('Prefer not to say', Gender.preferNotToSay),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveGender,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF333333),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile(String title, Gender value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.black54),
        child: RadioListTile<Gender>(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          value: value,
          groupValue: _selectedGender,
          activeColor: const Color(0xFF66D2A3),
          onChanged: (Gender? newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
        ),
      ),
    );
  }
}
