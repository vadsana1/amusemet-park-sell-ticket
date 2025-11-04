class Ride {
  final int rideId;
  final String name;
  final String description;
  final String thrillLevel;
  final int heightRequirement;
  final int durationMin;
  final String locationLat;
  final String locationLng;

  const Ride({
    required this.rideId,
    required this.name,
    required this.description,
    required this.thrillLevel,
    required this.heightRequirement,
    required this.durationMin,
    required this.locationLat,
    required this.locationLng,
  });

  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      rideId: map['ride_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      thrillLevel: map['thrill_level'] as String,
      heightRequirement: map['height_requirement'] as int,
      durationMin: map['duration_min'] as int,
      locationLat: map['location_lat'] as String,
      locationLng: map['location_lng'] as String,
    );
  }
}
