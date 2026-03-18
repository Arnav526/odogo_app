import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:odogo_app/models/vehicle_model.dart';

class VehicleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _vehicles => _firestore.collection('vehicles');

  /// Adds a new vehicle to the database.
  Future<void> registerVehicle(VehicleModel vehicle) async {
    await _vehicles.doc(vehicle.registrationNum).set(vehicle.toJson());
  }

  /// Fetches the vehicle assigned to a specific driver.
  Future<VehicleModel?> getVehicleByDriver(String driverID) async {
    final snapshot = await _vehicles
        .where('driverID', isEqualTo: driverID)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return VehicleModel.fromJson(
        snapshot.docs.first.data() as Map<String, dynamic>,
      );
    }
    return null;
  }
}
