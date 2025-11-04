class PaymentMethod {
  final int id;
  final String code;
  final String name;
  final dynamic config;
  final bool isActive;
  final String createdAt; 
  final String updatedAt;

  const PaymentMethod({
    required this.id,
    required this.code,
    required this.name,
    this.config, 
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as int,
      code: map['code'] as String,
      name: map['name'] as String,
      config: map['config'],
      isActive: map['is_active'] as bool,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}
