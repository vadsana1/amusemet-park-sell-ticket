import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  
  final TextEditingController _field1Controller = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedProviderType;
  
  final List<String> _providerTypes = ['ປະເພດ 1', 'ປະເພດ 2', 'ປະເພດ 3'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back, color: Colors.black),
      //     onPressed: () => Navigator.of(context).pop(),
      //   ),
      // ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. ຫົວຂໍ້ (Title)
                const Text(
                  'ລົງທະບຽນ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),

                _buildTextField(
                  controller: _field1Controller,
                  hintText: '', 
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _nameController,
                  hintText: 'ຊື່ຜູ້ປະກອບ',
                ),
                const SizedBox(height: 20),

                _buildDropdownField(
                  hintText: 'ເລືອກປະເພດຜູ້ປະກອບ',
                  value: _selectedProviderType,
                  items: _providerTypes,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedProviderType = newValue;
                    });
                  },
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _locationController,
                  hintText: 'ສະຖານທີ່',
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () {
                    print('ຊື່ຜູ້ປະກອບ: ${_nameController.text}');
                    print('ປະເພດ: $_selectedProviderType');
                    print('ສະຖານທີ່: ${_locationController.text}');
                    // ...
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFE0D8B0,
                    ), // ສີເບຈ/ເຫຼືອງອ່ອນ
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ລົງທະບຽນ',
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget ສຳລັບສ້າງ TextField (ແບບບໍ່ມີໄອຄອນ)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[200], // ສີພື້ນຫຼັງຂອງຊ່ອງປ້ອນ
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none, // ບໍ່ເອົາເສັ້ນຂອບ
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 25.0,
        ),
      ),
    );
  }


  Widget _buildDropdownField({
    required String hintText,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 25.0,
        ),
      ),
      isExpanded: true,
    );
  }
}
