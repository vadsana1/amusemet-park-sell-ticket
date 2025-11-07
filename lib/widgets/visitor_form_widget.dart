import 'package:flutter/material.dart';

class VisitorFormWidget extends StatefulWidget {
  // ຮັບ Key, Controllers, ແລະ ຄ່າເລີ່ມຕົ້ນ ຈາກໜ້າແມ່ (PaymentPage)
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final String initialGender;
  // Callback ເພື່ອສົ່ງຄ່າ Gender ທີ່ເລືອກ ກັບຄືນໄປຫາໜ້າແມ່
  final ValueChanged<String> onGenderChanged;

  const VisitorFormWidget({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.phoneController,
    required this.initialGender,
    required this.onGenderChanged,
  });

  @override
  State<VisitorFormWidget> createState() => _VisitorFormWidgetState();
}

class _VisitorFormWidgetState extends State<VisitorFormWidget> {
  // State ຂອງ Gender ຈະຖືກຈັດການຢູ່ບ່ອນນີ້
  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender;
  }

  @override
  Widget build(BuildContext context) {
    // ໃຊ້ Form key ຈາກໜ້າແມ່
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          // --- Full Name ---
          TextFormField(
            controller: widget.fullNameController, // ໃຊ້ Controller ຈາກໜ້າແມ່
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
            // ບໍ່ຈຳເປັນຕ້ອງມີ onChanged ທີ່ເອີ້ນ setState(() {})
            // ເພາະ Controller ຈະອັບເດດຄ່າຂອງມັນເອງ
          ),
          const SizedBox(height: 16),

          // --- Phone ---
          TextFormField(
            controller: widget.phoneController, // ໃຊ້ Controller ຈາກໜ້າແມ່
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
        ],
      ),
    );
  }

  void _handleGenderChange(String? value) {
    if (value != null) {
      setState(() {
        _selectedGender = value;
      });
      // ສົ່ງຄ່າ Gender ໃໝ່ ກັບຄືນໄປຫາ PaymentPage
      widget.onGenderChanged(value);
    }
  }
}
