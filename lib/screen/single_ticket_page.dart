import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../models/cart_item.dart';
import '../models/payment_method.dart'; // <-- [ເພີ່ມ] 1. Import PaymentMethod
import '../widgets/quantity_stepper.dart'; 
import './payment_page.dart';

class SingleTicketPage extends StatefulWidget {
 // [ແກ້ໄຂ] 2. ຮັບ State ໃໝ່
 final List<Ticket> selectedTickets;
 final List<PaymentMethod> paymentMethods; // <-- ຕ້ອງຮັບອັນນີ້

 const SingleTicketPage({
  super.key, 
  required this.selectedTickets,
  required this.paymentMethods, // <-- ຕ້ອງຮັບອັນນີ້
 });

 @override
 State<SingleTicketPage> createState() => _SingleTicketPageState();
}

class _SingleTicketPageState extends State<SingleTicketPage> {
 final List<CartItem> _cart = [];
 Ticket? _currentSingleTicket; 
 int _inputAdultQty = 0;
 int _inputChildQty = 0;
 int _groupAdultQty = 0;
 int _groupChildQty = 0;
 double _totalPrice = 0.0;

 @override
 void didUpdateWidget(SingleTicketPage oldWidget) {
  super.didUpdateWidget(oldWidget);

  if (widget.selectedTickets.length == 1) {
      final newSelectedTicket = widget.selectedTickets.first;
      if (_currentSingleTicket?.ticketId != newSelectedTicket.ticketId) {
        _loadTicketForEditing(newSelectedTicket);
      }
  } 
    else if (widget.selectedTickets.length != 1) {
      if (_currentSingleTicket != null) {
        _resetInputs();
      }
  }

    if (widget.selectedTickets.length > 1 && 
        oldWidget.selectedTickets.length > 1 && 
        widget.selectedTickets != oldWidget.selectedTickets) {
      _resetGroupInputs();
    }
 }

 void _loadTicketForEditing(Ticket ticket) {
  setState(() {
   _currentSingleTicket = ticket;
   var existingItem = _findItemInCart(ticket);
   if (existingItem != null) {
    _inputAdultQty = existingItem.quantityAdult;
    _inputChildQty = existingItem.quantityChild;
   } else {
    _inputAdultQty = 0;
    _inputChildQty = 0;
   }
  });
 }

 void _resetInputs() {
  setState(() {
   _currentSingleTicket = null;
   _inputAdultQty = 0;
   _inputChildQty = 0;
  });
 }

  void _resetGroupInputs() {
    setState(() {
      _groupAdultQty = 0;
      _groupChildQty = 0;
    });
  }

 CartItem? _findItemInCart(Ticket ticket) {
  try {
      return _cart
    .firstWhere((item) => item.ticket.ticketId == ticket.ticketId);
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
   if (widget.selectedTickets.length == 1 && _currentSingleTicket?.ticketId == item.ticket.ticketId) {
    _inputAdultQty = 0;
    _inputChildQty = 0;
   }
      if (widget.selectedTickets.length > 1 && widget.selectedTickets.any((t) => t.ticketId == item.ticket.ticketId)) {
        _groupAdultQty = 0;
        _groupChildQty = 0;
      }
   _calculateTotal();
  });
 }

 void _updateCartItem(Ticket ticket, int adultQty, int childQty) {
  var existingItem = _findItemInCart(ticket);
  if (existingItem != null) {
   existingItem.quantityAdult = adultQty;
   existingItem.quantityChild = childQty;
   if (existingItem.totalQuantity <= 0) {
    _cart.remove(existingItem);
   }
  } else if (adultQty > 0 || childQty > 0) {
   _cart.add(
    CartItem(
     ticket: ticket,
     quantityAdult: adultQty,
     quantityChild: childQty,
    ),
   );
  }
 }

 void _updateSingleCart(String type, int change) {
  if (_currentSingleTicket == null) return; 
  setState(() {
   if (type == 'adult' && _inputAdultQty + change >= 0) {
    _inputAdultQty += change;
   } else if (type == 'child' && _inputChildQty + change >= 0) {
    _inputChildQty += change;
   }
   _updateCartItem(_currentSingleTicket!, _inputAdultQty, _inputChildQty);
   _calculateTotal();
  });
 }

 void _updateGroupCart(String type, int change) {
  if (widget.selectedTickets.isEmpty) return;
  setState(() {
   if (type == 'adult' && _groupAdultQty + change >= 0) {
    _groupAdultQty += change;
   } else if (type == 'child' && _groupChildQty + change >= 0) {
    _groupChildQty += change;
   }
   for (var ticket in widget.selectedTickets) {
    _updateCartItem(ticket, _groupAdultQty, _groupChildQty);
   }
   _calculateTotal();
  });
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
     const Text( 'ລາຍການ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
     const SizedBox(height: 16),
     _buildCartHeader(),
     const SizedBox(height: 8),
     Expanded(
      child: _cart.isEmpty
        ? const Center( child: Text('ຍັງບໍ່ມີລາຍການ'),)
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
    // 9a. ໂໝດວ່າງ (ເລືອກ 0 ໃບ)
    if (widget.selectedTickets.isEmpty) {
      return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text(
            'ປ້ອນຂໍ້ມູນ',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: 0.5,
            child: Column(
              children: [
                const Center(child: Text('กรุณาเลือกตั๋วจากด้านซ้าย', style: TextStyle(fontSize: 16, color: Colors.black54))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ຜູ້ໃຫຍ່', style: TextStyle(fontSize: 16)), 
                    // [ແກ້ໄຂ] 3. ປ່ຽນ null ເປັນ () {}
                    QuantityStepper(quantity: 0, onIncrement: () {}, onDecrement: () {}),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ເດັກນ້ອຍ', style: TextStyle(fontSize: 16)), 
                    // [ແກ້ໄຂ] 4. ປ່ຽນ null ເປັນ () {}
                    QuantityStepper(quantity: 0, onIncrement: () {}, onDecrement: () {}),
                  ],
                ),
              ],
            ),
          )
         ],
      );
    } 
    // 9b. ໂໝດກຸ່ມ (ເລືອກ 2+ ໃບ)
    else if (widget.selectedTickets.length > 1) {
      String groupTitle = 'โหมดกลุ่ม (${widget.selectedTickets.length} รายการ)';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ປ້ອນຂໍ້ມູນ: $groupTitle', 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ຜູ້ໃຫຍ່ (ทั้งหมด)', style: TextStyle(fontSize: 16)), 
              QuantityStepper(
                quantity: _groupAdultQty,
                onIncrement: () => _updateGroupCart('adult', 1),
                onDecrement: () => _updateGroupCart('adult', -1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text( 'ເດັກນ້ອຍ (ทั้งหมด)', style: TextStyle(fontSize: 16),), 
              QuantityStepper(
                quantity: _groupChildQty,
                onIncrement: () => _updateGroupCart('child', 1),
                onDecrement: () => _updateGroupCart('child', -1),
              ),
            ],
          ),
        ],
      );
    } 
    // 9c. ໂໝດດ່ຽວ (ເລືອກ 1 ໃບ)
    else {
      String ticketName = _currentSingleTicket?.ticketName ?? "กำลังโหลด..."; 

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ປ້ອນຂໍ້ມູນ: $ticketName',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ຜູ້ໃຫຍ່', style: TextStyle(fontSize: 16)), 
              QuantityStepper(
                quantity: _inputAdultQty,
                onIncrement: () => _updateSingleCart('adult', 1),
                onDecrement: () => _updateSingleCart('adult', -1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text( 'ເດັກນ້ອຍ', style: TextStyle(fontSize: 16),), 
              QuantityStepper(
                quantity: _inputChildQty,
                onIncrement: () => _updateSingleCart('child', 1),
                onDecrement: () => _updateSingleCart('child', -1),
              ),
            ],
          ),
        ],
      );
    }
  }

 Widget _buildCartHeader() {
  return Padding(
   padding: const EdgeInsets.symmetric(vertical: 8.0),
   child: Row(
    children: [
     const Expanded( flex: 1, child: Text( "ລ/ດ", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, ),),
     const Expanded( flex: 2, child: Text( "ຈຳນວນ", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, ),),
     const Expanded( flex: 5, child: Text( "ຊື່", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, ),),
     Expanded( flex: 2, child: Text( "ເດັກ", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, ),),
     Expanded( flex: 2, child: Text( "ຜູ້ໃຫຍ່", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, ),),
     Expanded( flex: 3, child: Text( "ລາຄາລວມ", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right, ),),
     const SizedBox(width: 40),
    ],
   ),
  );
 }

 Widget _buildCartItemRow(CartItem item, int index) {
    final bool isSelected = widget.selectedTickets.any((t) => t.ticketId == item.ticket.ticketId);

  return Container(
   padding: const EdgeInsets.symmetric(vertical: 8.0),
   color: isSelected
     ? Colors.teal.withAlpha(26) 
     : Colors.transparent,
   child: Row(
    children: [
     Expanded( flex: 1, child: Text( (index + 1).toString(), textAlign: TextAlign.center, ),),
     Expanded( flex: 2, child: Text( item.totalQuantity.toString(), textAlign: TextAlign.center, ),),
     Expanded( flex: 5, child: Text(item.ticket.ticketName),),
     Expanded( flex: 2, child: Text( item.quantityChild.toString(), textAlign: TextAlign.center, ),),
     Expanded( flex: 2, child: Text( item.quantityAdult.toString(), textAlign: TextAlign.center, ),),
     Expanded( flex: 3, child: Text( "${item.totalPrice.toStringAsFixed(0)} ກີບ", textAlign: TextAlign.right, ),),
     Container(
      width: 40,
      alignment: Alignment.center,
      child: IconButton(
       icon: Icon(Icons.delete_outline, color: Colors.red[700]),
       iconSize: 20,
       padding: EdgeInsets.zero,
       constraints: const BoxConstraints(),
       onPressed: () {
        _removeItemFromCart(item);
       },
      ),
     ),
    ],
   ),
  );
 }

 Widget _buildTotalSection() {
  return Column(
   children: [
    Row(
     mainAxisAlignment: MainAxisAlignment.spaceBetween,
     children: [
      const Text( 'ລາຄາທັງໝົດ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
      Text(
       '${_totalPrice.toStringAsFixed(0)} ກີບ',
       style: const TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A9A8B),),
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
       textStyle: const TextStyle( fontSize: 18, fontFamily: 'Phetsarath_OT',),
      ),
      onPressed: _cart.isEmpty
        ? null
        : () {
          Navigator.push(
           context,
           MaterialPageRoute(
            builder: (context) => PaymentPage(
             cart: _cart,
             totalPrice: _totalPrice,
             // [ແກ້ໄຂ] 5. ສົ່ງ paymentMethods ທີ່ຮັບມາ
             paymentMethods: widget.paymentMethods, 
            ),
           ),
          );
         },
      child: const Text('ຊຳລະເງິນ'), // 'ชำระเงิน'
     ),
    ),
   ],
  );
 }
}