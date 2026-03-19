// import 'package:flutter/material.dart';

// class HomeAddressEditScreen extends StatefulWidget {
//   const HomeAddressEditScreen({super.key});

//   @override
//   State<HomeAddressEditScreen> createState() => _HomeAddressEditScreenState();
// }

// class _HomeAddressEditScreenState extends State<HomeAddressEditScreen> {
//   // Controller to capture the home address, pre-filled with your example
//   final TextEditingController _addressController = TextEditingController(text: 'Hall 12');

//   @override
//   void dispose() {
//     _addressController.dispose();
//     super.dispose();
//   }

//   void _saveAddress() {
//     print("Saving new home address: ${_addressController.text}");

//     // Show a quick success popup
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Home address updated successfully!'),
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
//         // The essential Back Button!
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('Inesh', style: TextStyle(color: Colors.white)),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: CircleAvatar(
//               radius: 16,
//               backgroundColor: const Color(0xFF66D2A3), // OdoGo Green
//               child: const Icon(Icons.person, color: Colors.white, size: 20),
//             ),
//           )
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
//                   Icon(Icons.home_outlined, size: 40, color: Colors.black87),
//                   SizedBox(width: 12),
//                   Text(
//                     'Home Address',
//                     style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 40),
//               TextField(
//                 controller: _addressController,
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: Colors.grey[200],
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   hintText: 'Enter your hostel or hall number',
//                 ),
//                 style: const TextStyle(fontSize: 18),
//               ),
//               const SizedBox(height: 40),

//               // Full-width button to match the other settings screens
//               ElevatedButton(
//                 onPressed: _saveAddress,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF333333),
//                   minimumSize: const Size.fromHeight(56),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
    if (user != null && user.roomNo != null) {
      _addressController.text = user.roomNo!;
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
        .updateRoomNumber(_addressController.text.trim());
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.home_outlined, size: 40, color: Colors.black87),
                  SizedBox(width: 12),
                  Text(
                    'Home Address',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  hintText: 'Enter your hostel or hall number',
                ),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
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
    );
  }
}
