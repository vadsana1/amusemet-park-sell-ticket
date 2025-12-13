class ThemeParkProfile {
  final int parkId;
  final String name;
  final String? shortName;
  final String? appName;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? phone;
  final String? email;
  final String? website;
  final String? openingTime;
  final String? closingTime;
  final String? timezone;
  final String? currency;
  final String? picture; // นี่คือ Logo URL
  final bool isActive;

  ThemeParkProfile({
    required this.parkId,
    required this.name,
    this.shortName,
    this.appName,
    this.description,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.phone,
    this.email,
    this.website,
    this.openingTime,
    this.closingTime,
    this.timezone,
    this.currency,
    this.picture,
    required this.isActive,
  });

  // Factory สำหรับแปลง JSON object (ส่วนของ "data") มาเป็น Class
  factory ThemeParkProfile.fromJson(Map<String, dynamic> json) {
    return ThemeParkProfile(
      parkId: json['park_id'] ?? 0,
      name: json['name'] ?? '',
      shortName: json['short_name'],
      appName: json['app_name'],
      description: json['description'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postal_code'],
      country: json['country'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      openingTime: json['opening_time'],
      closingTime: json['closing_time'],
      timezone: json['timezone'],
      currency: json['currency'],
      picture: json['picture'], // Map ตรงกับ JSON key "picture"
      // แปลงเป็น bool อย่างปลอดภัย (กรณี API ส่งมาเป็น 1/0 หรือ true/false)
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}
