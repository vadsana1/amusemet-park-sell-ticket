import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../models/payment_method.dart';
import '../models/cart_item.dart';
import 'payment_page.dart';
import '../services/payment_api.dart';
import '../widgets/side_menu.dart';
import '../widgets/home_page_header.dart';
import 'package_ticket_page.dart';
import 'single_ticket_list_page.dart';
import 'single_ticket_page.dart';
import 'user_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PaymentApi _paymentApi = PaymentApi();

  final GlobalKey<State<SingleTicketPage>> _ticketPageStateKey = GlobalKey();

  int _selectedIndex = 0;
  Ticket? _selectedTicket;
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoadingMethods = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoadingMethods = true);

    try {
      final fetchedMethods = await _paymentApi.fetchPaymentMethods();

      if (mounted) {
        setState(() {
          _paymentMethods = fetchedMethods;
          _isLoadingMethods = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMethods = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to load payment methods. Please try again.'),
          ),
        );
      }
    }
  }

  void _onMenuItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedTicket = null;
      (_ticketPageStateKey.currentState as dynamic)?.clearAllState();
    });
  }

  void _onTicketSelected(Ticket ticket) {
    setState(() {
      _selectedTicket = ticket;
    });
  }

  void _startPaymentProcess(
    List<CartItem> cart,
    double totalPrice,
    int adultQty,
    int childQty,
  ) async {
    if (cart.isEmpty) return;
    if (!mounted) return;

    final bool? resetFlag = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          cart: cart,
          totalPrice: totalPrice,
          adultQty: adultQty,
          childQty: childQty,
          paymentMethods: _paymentMethods, // 👈 ส่งข้อมูลจริง (ที่โหลดมา) ไปต่อ
        ),
      ),
    );

    if (resetFlag == true) {
      (_ticketPageStateKey.currentState as dynamic)?.clearAllState();
      setState(() {
        _selectedTicket = null;
      });
    }
  }

  Widget _buildCurrentPage() {
    if (_isLoadingMethods) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: SingleTicketListPage(
                onTicketSelected: _onTicketSelected,
                selectedTicket: _selectedTicket,
              ),
            ),
            SingleTicketPage(
              key: _ticketPageStateKey,
              ticket: _selectedTicket,
              onTicketSelected: _onTicketSelected,
              paymentMethods: _paymentMethods,
              onCheckout: _startPaymentProcess,
            ),
          ],
        );

      case 1:
        return const PackageTicketPage();
      case 2:
        return const UserPage();
      default:
        return const Center(child: Text("Page not found"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HomePageHeader(),
            Expanded(
              child: Row(
                children: [
                  SideMenu(
                    selectedIndex: _selectedIndex,
                    onMenuItemTapped: _onMenuItemTapped,
                  ),
                  Expanded(child: _buildCurrentPage()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
