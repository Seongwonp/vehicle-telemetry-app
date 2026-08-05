import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip.dart';
import 'vehicle_providers.dart';

@immutable
class TripQuery {
  final String vehicleId;
  final int hours;

  const TripQuery({required this.vehicleId, required this.hours});

  @override
  bool operator ==(Object other) =>
      other is TripQuery &&
      other.vehicleId == vehicleId &&
      other.hours == hours;

  @override
  int get hashCode => Object.hash(vehicleId, hours);
}

class TripParsingException implements Exception {
  final Object cause;

  const TripParsingException(this.cause);
}

final tripsProvider = FutureProvider.autoDispose
    .family<List<Trip>, TripQuery>((ref, query) async {
  final data = await ref.watch(apiClientProvider).getTrips(
        query.vehicleId,
        hours: query.hours,
      );

  try {
    return data
        .map((item) => Trip.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(TripParsingException(error), stackTrace);
  }
});
