import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Imports Models
import '../models/ticket.dart';
import '../models/payment_method.dart';
import '../models/cart_item.dart';

// Imports Pages & Widgets
import 'payment_page.dart';
import '../services/payment_api.dart';
import '../services/sticker_printer_service.dart';
import '../widgets/side_menu.dart';
import '../widgets/home_page_header.dart';
import 'package_ticket_page.dart';
import 'single_ticket_list_page.dart';
import 'single_ticket_page.dart';
import 'user_page.dart';
import 'shift_summary_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // API & Storage
  final PaymentApi _paymentApi = PaymentApi();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 🆕 Reference to printer service
  final StickerPrinterService _printerService = StickerPrinterService.instance;

  // Key for clearing values in SingleTicketPage (right side)
  final GlobalKey<State<SingleTicketPage>> _ticketPageStateKey = GlobalKey();

  // State Variables
  int _selectedIndex = 0;
  Ticket? _selectedTicket;
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoadingMethods = true;
  String? _currentUserId;

  // [Important] Variable to store current cart to send to List page on left to check status
  List<CartItem> _currentCart = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _loadUserId();
    // Auto-connect to TSC printer when user reaches home page
    StickerPrinterService.instance.autoConnectOnStartup();

    // 🆕 ฟังการแจ้งเตือนการเชื่อมต่อใหม่
    _listenToReconnectNotifier();
  }

  @override
  void dispose() {
    // 🔧 Remove listeners when widget is disposed
    _printerService.needsReconnectNotifier.removeListener(_onReconnectNotified);
    _printerService.needsManualReconnectNotifier
        .removeListener(_onManualReconnectNotified);
    _printerService.isReconnectingNotifier
        .removeListener(_onReconnectingChanged);
    super.dispose();
  }

  // 🔧 Stored listener function for proper cleanup
  void _onReconnectNotified() {
    if (!mounted) return;

    // Use addPostFrameCallback to safely access context after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Only show SnackBar when auto-connected successfully
      if (_printerService.needsReconnectNotifier.value &&
          _printerService.isConnectedNotifier.value) {
        _showAutoConnectedSnackBar();
        _printerService.clearReconnectFlag();
      }
    });
  }

  // 🆕 ฟังการแจ้งเตือนการเชื่อมต่อใหม่
  void _listenToReconnectNotifier() {
    _printerService.needsReconnectNotifier.addListener(_onReconnectNotified);
    _printerService.needsManualReconnectNotifier
        .addListener(_onManualReconnectNotified);
    _printerService.isReconnectingNotifier.addListener(_onReconnectingChanged);
  }

  // 🆕 Show/hide loading dialog when reconnecting
  void _onReconnectingChanged() {
    if (!mounted) return;

    if (_printerService.isReconnectingNotifier.value) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('ກຳລັງເຊື່ອມຕໍ່ເຄື່ອງພິມ...'),
            ],
          ),
        ),
      );
    } else {
      // Hide dialog if currently showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  // 🔧 Manual reconnect notifier handler (kept for fallback, but now mostly unused)
  // Auto-connect now handles replug silently via needsReconnectNotifier
  void _onManualReconnectNotified() {
    // This is now mostly unused since auto-connect works reliably after plugin fix
    // Kept for potential fallback scenarios
    if (!mounted) return;
    if (_printerService.needsManualReconnectNotifier.value) {
      debugPrint('🔔 Manual reconnect triggered (fallback mode)');
      _printerService.needsManualReconnectNotifier.value = false;
    }
  }

  // Auto-connect SnackBar shown via _onReconnectNotified

  // 🆕 แสดง SnackBar เมื่อ auto-connect สำเร็จ
  void _showAutoConnectedSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.print, color: Colors.white),
            SizedBox(width: 10),
            Text('✅ ເຊື່ອມຕໍ່ເຄື່ອງພິມສຳເລັດແລ້ວ'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // Load User ID from Storage
  Future<void> _loadUserId() async {
    final id = await _storage.read(key: 'user_id');
    if (mounted) {
      setState(() {
        _currentUserId = id;
      });
    }
  }

  // Load payment methods
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
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to load payment methods.'),
          ),
        );
      }
    }
  }

  // Change left menu (Ticket, Package, Shift, User)
  void _onMenuItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      // Reset values when changing page
      _selectedTicket = null;
      _currentCart.clear(); // Clear cart in Home memory

      // Clear values in SingleTicketPage (if key still exists)
      (_ticketPageStateKey.currentState as dynamic)?.clearAllState();
    });
  }

  // When ticket is selected from List page on left
  void _onTicketSelected(Ticket ticket) {
    setState(() {
      _selectedTicket = ticket;
    });
  }

  // [Important] Function to receive value when cart on right page changes
  void _handleCartChanged(List<CartItem> newCart) {
    // Update State to pass to left page (SingleTicketListPage) to be aware
    setState(() {
      _currentCart = newCart;
    });
  }

  // Start payment process
  void _startPaymentProcess(
    List<CartItem> cart,
    double totalPrice,
    int adultQty,
    int childQty,
  ) async {
    if (cart.isEmpty) return;
    if (!mounted) return;

    // Go to PaymentPage
    final bool? resetFlag = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          cart: cart,
          totalPrice: totalPrice,
          adultQty: adultQty,
          childQty: childQty,
          paymentMethods: _paymentMethods,
        ),
      ),
    );

    // If payment successful (returns true) clear all values
    if (resetFlag == true) {
      (_ticketPageStateKey.currentState as dynamic)?.clearAllState();
      setState(() {
        _selectedTicket = null;
        _currentCart.clear();
      });
    }
  }

  // Main content display section, according to selected menu
  Widget _buildCurrentPage() {
    if (_isLoadingMethods) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0: // Single Ticket Sales page
        return Row(
          children: [
            // Ticket list display section (left)
            Expanded(
              flex: 3,
              child: SingleTicketListPage(
                onTicketSelected: _onTicketSelected,
                selectedTicket: _selectedTicket,
                cart:
                    _currentCart, // Send cart to check which tickets are selected to dim
              ),
            ),
            // Quantity and price management section (right)
            SingleTicketPage(
              key: _ticketPageStateKey,
              ticket: _selectedTicket,
              paymentMethods: _paymentMethods,
              onTicketSelected: _onTicketSelected,
              onCheckout: _startPaymentProcess,
              onCartChanged:
                  _handleCartChanged, // Receive cart values back to update
            ),
          ],
        );

      case 1: // Package Ticket page
        return const PackageTicketPage();

      case 2: // Shift Summary page
        if (_currentUserId == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ShiftSummaryScreen(userId: _currentUserId!);

      case 3: // User Profile page
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
            // Header section at top
            const HomePageHeader(),

            // Main content area
            Expanded(
              child: Row(
                children: [
                  // Left menu bar
                  SideMenu(
                    selectedIndex: _selectedIndex,
                    onMenuItemTapped: _onMenuItemTapped,
                  ),
                  // Content that changes according to menu
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
