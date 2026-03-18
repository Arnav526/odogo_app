import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';
import '../repositories/trip_repository.dart';

final tripRepositoryProvider = Provider((ref) => TripRepository());

// Stream for Drivers to see available rides
final pendingTripsProvider = StreamProvider<List<TripModel>>((ref) {
  // Changed to ref.watch for better reactivity
  return ref.watch(tripRepositoryProvider).streamPendingTrips();
});

// Stream for Commuters to watch their specific active ride
final activeTripStreamProvider = StreamProvider.family<TripModel?, String>((
  ref,
  tripID,
) {
  // Changed to ref.watch for better reactivity
  return ref.watch(tripRepositoryProvider).streamTrip(tripID);
});

// 1. UPDATED to NotifierProvider
final tripControllerProvider =
    NotifierProvider<TripController, AsyncValue<void>>(() {
      return TripController();
    });

// 2. UPDATED to Notifier
class TripController extends Notifier<AsyncValue<void>> {
  // 3. Notifiers use build() to set the initial state instead of super()
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  // 4. Easy getter to access the repository using the internal 'ref'
  TripRepository get _repository => ref.read(tripRepositoryProvider);

  Future<void> requestRide(TripModel trip) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createTrip(trip);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> acceptRide(String tripID, String driverID) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTripStatus(
        tripID: tripID,
        status: 'confirmed',
        driverID: driverID,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
