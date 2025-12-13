import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket.dart';
import '../models/cart_item.dart';
import '../models/payment_method.dart';
import '../widgets/quantity_stepper.dart';

typedef OnCheckoutCallback =
    void Function(
      List<CartItem> cart,
      double totalPrice,
      int adultQty,
      int childQty,
    );

class SingleTicketPage extends StatefulWidget {
  final Ticket? ticket;
  final List<PaymentMethod> paymentMethods;
  final void Function(Ticket ticket) onTicketSelected;
  final OnCheckoutCallback onCheckout;
  // [เพิ่ม] รับ callback เพื่อส่งตะกร้าออกไป
  final Function(List<CartItem>) onCartChanged;

  const SingleTicketPage({
    super.key,
    this.ticket,
    required this.paymentMethods,
    required this.onTicketSelected,
    required this.onCheckout,
    required this.onCartChanged,
  });

  @override
  State<SingleTicketPage> createState() => _SingleTicketPageState();
}

class _SingleTicketPageState extends State<SingleTicketPage> {
  final List<CartItem> _cart = [];
  int _inputAdultQty = 0;
  int _inputChildQty = 0;
  double _totalPrice = 0.0;

  void clearAllState() {
    setState(() {
      _cart.clear();
      _inputAdultQty = 0;
      _inputChildQty = 0;
      _totalPrice = 0.0;
    });
    _notifyCartChange();
  }

  // [เพิ่ม] ฟังก์ชันส่งค่าตะกร้าออกแบบปลอดภัย (แก้จอแดง)
  void _notifyCartChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onCartChanged(List.from(_cart));
      }
    });
  }

  // --- LOGIC เดิมของคุณ (Global Stepper, Add-only) ---
  @override
  void didUpdateWidget(SingleTicketPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ticket != null && widget.ticket != oldWidget.ticket) {
      setState(() {
        var existingItem = _findItemInCart(widget.ticket!);
        if (existingItem == null) {
          // Logic เดิม: ถ้าไม่มีให้ Add ใหม่
          _cart.add(
            CartItem(
              ticket: widget.ticket!,
              quantityAdult: _inputAdultQty,
              quantityChild: _inputChildQty,
            ),
          );
          _calculateTotal();
        }
      });
      // เรียก notify หลัง update เสร็จ (แก้จอแดงด้วย addPostFrameCallback ข้างใน)
      _notifyCartChange();
    }
  }

  CartItem? _findItemInCart(Ticket ticket) {
    try {
      return _cart.firstWhere(
        (item) => item.ticket.ticketId == ticket.ticketId,
      );
    } catch (e) {
      return null;
    }
  }

  void _calculateTotal() {
    setState(() {
      _totalPrice = 0.0;
      for (var item in _cart) {
        _totalPrice += item.totalPrice;
      }
    });
  }

  void _removeItemFromCart(CartItem item) {
    setState(() {
      _cart.remove(item);
      _calculateTotal();
    });
    _notifyCartChange(); // แจ้งออกไปเมื่อลบ
  }

  void _updateCart(String type, int change) {
    setState(() {
      if (type == 'adult' && _inputAdultQty + change >= 0) {
        _inputAdultQty += change;
      } else if (type == 'child' && _inputChildQty + change >= 0) {
        _inputChildQty += change;
      }
      for (var item in _cart) {
        item.quantityAdult = _inputAdultQty;
        item.quantityChild = _inputChildQty;
      }
      _cart.removeWhere((item) => item.totalQuantity <= 0);
      _calculateTotal();
    });
    _notifyCartChange(); // แจ้งออกไปเมื่อแก้จำนวน
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      color: const Color(0xFFEAEAEA),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputSection(),
          const Divider(height: 32),
          const Text(
            'ລາຍການ',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCartHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: _cart.isEmpty
                ? const Center(child: Text('ຍັງບໍ່ມີລາຍການ'))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return _buildCartItemRow(item, index);
                    },
                  ),
          ),
          _buildTotalSection(),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    String ticketName = widget.ticket?.ticketName ?? "ກະລຸນາເລືອກປີ້";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ຊື່ເຄື່ອງຫຼິ້ນ: $ticketName',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        Opacity(
          opacity: 1.0,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ຜູ້ໃຫຍ່', style: TextStyle(fontSize: 16)),
                  QuantityStepper(
                    quantity: _inputAdultQty,
                    onIncrement: () => _updateCart('adult', 1),
                    onDecrement: () => _updateCart('adult', -1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ເດັກນ້ອຍ', style: TextStyle(fontSize: 16)),
                  QuantityStepper(
                    quantity: _inputChildQty,
                    onIncrement: () => _updateCart('child', 1),
                    onDecrement: () => _updateCart('child', -1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Header และ CartRow ใช้โค้ดเดิมของคุณได้เลย
  Widget _buildCartHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: const [
          Expanded(
            flex: 1,
            child: Text(
              "ລ/ດ",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "ຈຳນວນ",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              "ຊື່",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "ເດັກ",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "ຜູ້ໃຫຍ່",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              "ລາຄາລວມ",
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCartItemRow(CartItem item, int index) {
    final NumberFormat currencyFormat = NumberFormat("#,##0", "en_US");
    final bool isSelected = widget.ticket?.ticketId == item.ticket.ticketId;
    return InkWell(
      onTap: null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        color: isSelected ? Colors.teal.withAlpha(26) : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text((index + 1).toString(), textAlign: TextAlign.center),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.totalQuantity.toString(),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(flex: 5, child: Text(item.ticket.ticketName)),
            Expanded(
              flex: 2,
              child: Text(
                item.quantityChild.toString(),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.quantityAdult.toString(),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                "${currencyFormat.format(item.totalPrice)} ກີບ",
                textAlign: TextAlign.right,
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _removeItemFromCart(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    final NumberFormat currencyFormat = NumberFormat("#,##0", "en_US");
    final bool canCheckout = _inputAdultQty + _inputChildQty > 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ລາຄາທັງໝົດ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${currencyFormat.format(_totalPrice)} ກີບ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A9A8B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A9A8B),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: canCheckout
                ? () {
                    widget.onCheckout(
                      _cart,
                      _totalPrice,
                      _inputAdultQty,
                      _inputChildQty,
                    );
                  }
                : null,
            child: const Text(
              'ຊຳລະເງິນ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
