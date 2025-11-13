import 'package:flutter/material.dart';

class VisitorFormWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final String initialGender;
  final ValueChanged<String> onGenderChanged;

  final String initialVisitorType;
  final ValueChanged<String> onVisitorTypeChanged;

  const VisitorFormWidget({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.phoneController,
    required this.initialGender,
    required this.onGenderChanged,
    required this.initialVisitorType, 
    required this.onVisitorTypeChanged, 
  });

  @override
  State<VisitorFormWidget> createState() => _VisitorFormWidgetState();
}

class _VisitorFormWidgetState extends State<VisitorFormWidget> {
  late String _selectedGender;
  late String _selectedVisitorType; 

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender;
    _selectedVisitorType = widget.initialVisitorType;
  }

  void _handleVisitorTypeChange(String? value) {
    if (value != null) {
      setState(() {
        _selectedVisitorType = value;
      });
      widget.onVisitorTypeChanged(value);
    }
  }

  void _handleGenderChange(String? value) {
    if (value != null) {
      setState(() {
        _selectedGender = value;
      });
      widget.onGenderChanged(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          // --- Full Name ---
          TextFormField(
            controller: widget.fullNameController, 
            decoration: const InputDecoration(
              labelText: 'ຊື່ເຕັມ (ชื่อเต็ม)',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'ກະລຸນາປ້ອນຊື່';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // --- Phone ---
          TextFormField(
            controller: widget.phoneController, 
            decoration: const InputDecoration(
              labelText: 'ເບີໂທ (เบอร์โทร)',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'ກະລຸນາປ້ອນເບີໂທ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // --- Gender ---
          Row(
            children: [
              const Text('ເພດ (เพศ):', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Radio<String>(
                value: 'male',
                groupValue: _selectedGender,
                onChanged: _handleGenderChange,
              ),
              const Text('ຊາຍ (ชาย)'),
              Radio<String>(
                value: 'female',
                groupValue: _selectedGender,
                onChanged: _handleGenderChange,
              ),
              const Text('ຍິງ (หญิง)'),
            ],
          ),

          Row(
            children: [
              const Text(
                'ປະເພດຜູ້ຊື້ (Purchaser Type):',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Radio<String>(
                value: 'adult',
                groupValue: _selectedVisitorType,
                onChanged: _handleVisitorTypeChange,
              ),
              const Text('ຜູ້ໃຫຍ່ (Adult)'),
              Radio<String>(
                value: 'child',
                groupValue: _selectedVisitorType,
                onChanged: _handleVisitorTypeChange,
              ),
              const Text('ເດັກ (Child)'),
            ],
          ),
        ],
      ),
    );
  }
}
