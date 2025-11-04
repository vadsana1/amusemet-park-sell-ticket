import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantityStepper({
    Key? key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ปุ่มลบ (-)
        SizedBox(
          width: 30,
          height: 30,
          child: InkWell(
            onTap: onDecrement,
            child: const DecoratedBox(
              decoration: BoxDecoration(color: Colors.white),
              child: Icon(Icons.remove, size: 18),
            ),
          ),
        ),
        // จำนวน
        Container(
          width: 40,
          height: 30,
          alignment: Alignment.center,
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            quantity.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // ปุ่มเพิ่ม (+)
        SizedBox(
          width: 30,
          height: 30,
          child: InkWell(
            onTap: onIncrement,
            child: const DecoratedBox(
              decoration: BoxDecoration(color: Colors.white),
              child: Icon(Icons.add, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
