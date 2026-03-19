// import 'package:flutter/material.dart';

// class EditWorkAddressScreen extends StatefulWidget {
//   const EditWorkAddressScreen({super.key});

//   @override
//   State<EditWorkAddressScreen> createState() => _EditWorkAddressScreenState();
// }

// class _EditWorkAddressScreenState extends State<EditWorkAddressScreen> {
//   // Controller to capture the work address, pre-filled with 'OAT'
//   final TextEditingController _addressController = TextEditingController(text: 'OAT');

//   @override
//   void dispose() {
//     _addressController.dispose();
//     super.dispose();
//   }

//   void _saveAddress() {
//     print("Saving new work address: ${_addressController.text}");

//     // Show a quick success popup
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Work address updated successfully!'),
//         backgroundColor: Colors.green,
//       ),
//     );

//     // Return to the Profile Page
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         // The essential Back Button
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('Inesh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         actions: const [
//           Padding(
//             padding: EdgeInsets.only(right: 16.0),
//             child: CircleAvatar(
//               radius: 16,
//               backgroundColor: Color(0xFF66D2A3), // Standardized OdoGo Green
//               child: Icon(Icons.person, color: Colors.white, size: 20),
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Row(
//                 children: [
//                   Icon(Icons.work, color: Color.fromARGB(255, 0, 0, 0), size: 32), // Kept your orange highlight
//                   SizedBox(width: 12),
//                   Text('Work Address', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//                 ],
//               ),
//               const SizedBox(height: 32),
//               TextField(
//                 controller: _addressController,
//                 decoration: InputDecoration(
//                   labelText: 'Company Name / Address',
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: const BorderSide(color: Colors.green, width: 2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: _saveAddress,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color.fromARGB(255, 0, 0, 0),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';

class EditWorkAddressScreen extends ConsumerStatefulWidget {
  const EditWorkAddressScreen({super.key});
  @override
  ConsumerState<EditWorkAddressScreen> createState() =>
      _EditWorkAddressScreenState();
}

class _EditWorkAddressScreenState extends ConsumerState<EditWorkAddressScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    // Load Work Address from savedLocations[0]
    if (user != null &&
        user.savedLocations != null &&
        user.savedLocations!.isNotEmpty) {
      _addressController.text = user.savedLocations![0];
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    setState(() => _isLoading = true);
    await ref
        .read(userControllerProvider.notifier)
        .updateWorkAddress(_addressController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Work address updated!'),
        backgroundColor: Colors.green,
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
                  Icon(Icons.work, color: Colors.black, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'Work Address',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Company Name / Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
