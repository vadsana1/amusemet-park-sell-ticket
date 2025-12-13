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

  // Key สำหรับสั่งเคลียร์ค่าในหน้า SingleTicketPage (หน้าขวา)
  final GlobalKey<State<SingleTicketPage>> _ticketPageStateKey = GlobalKey();

  // State Variables
  int _selectedIndex = 0;
  Ticket? _selectedTicket;
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoadingMethods = true;
  String? _currentUserId;

  // [สำคัญ] ตัวแปรเก็บตะกร้าปัจจุบัน เพื่อส่งไปให้หน้า List ทางซ้ายเช็คสถานะ
  List<CartItem> _currentCart = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _loadUserId();
    // Auto-connect to TSC printer when user reaches home page
    StickerPrinterService.instance.autoConnectOnStartup();
  }

  // โหลด User ID จาก Storage
  Future<void> _loadUserId() async {
    final id = await _storage.read(key: 'user_id');
    if (mounted) {
      setState(() {
        _currentUserId = id;
      });
    }
  }

  // โหลดวิธีการชำระเงิน
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

  // เปลี่ยนเมนูแถบซ้ายสุด (Ticket, Package, Shift, User)
  void _onMenuItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      // รีเซ็ตค่าเมื่อเปลี่ยนหน้า
      _selectedTicket = null;
      _currentCart.clear(); // เคลียร์ตะกร้าในความจำของ Home

      // สั่งเคลียร์ค่าใน SingleTicketPage (ถ้าคีย์ยังอยู่)
      (_ticketPageStateKey.currentState as dynamic)?.clearAllState();
    });
  }

  // เมื่อเลือกตั๋วจากหน้า List ทางซ้าย
  void _onTicketSelected(Ticket ticket) {
    setState(() {
      _selectedTicket = ticket;
    });
  }

  // [สำคัญ] ฟังก์ชันรับค่าเมื่อตะกร้าในหน้าขวามีการเปลี่ยนแปลง
  void _handleCartChanged(List<CartItem> newCart) {
    // อัปเดต State เพื่อส่งต่อให้หน้าซ้าย (SingleTicketListPage) รับรู้
    setState(() {
      _currentCart = newCart;
    });
  }

  // เริ่มกระบวนการชำระเงิน
  void _startPaymentProcess(
    List<CartItem> cart,
    double totalPrice,
    int adultQty,
    int childQty,
  ) async {
    if (cart.isEmpty) return;
    if (!mounted) return;

    // ไปหน้า PaymentPage
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

    // ถ้าจ่ายเงินสำเร็จ (ได้ค่า true กลับมา) ให้เคลียร์ค่าทั้งหมด
    if (resetFlag == true) {
      (_ticketPageStateKey.currentState as dynamic)?.clearAllState();
      setState(() {
        _selectedTicket = null;
        _currentCart.clear();
      });
    }
  }

  // ส่วนแสดงผลเนื้อหาหลัก ตามเมนูที่เลือก
  Widget _buildCurrentPage() {
    if (_isLoadingMethods) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0: // หน้าขายตั๋วรายใบ (Single Ticket)
        return Row(
          children: [
            // ส่วนแสดงรายการตั๋ว (ซ้าย)
            Expanded(
              flex: 3,
              child: SingleTicketListPage(
                onTicketSelected: _onTicketSelected,
                selectedTicket: _selectedTicket,
                cart:
                    _currentCart, // ส่งตะกร้าไปเพื่อเช็คว่าตั๋วไหนเลือกแล้วให้จางลง
              ),
            ),
            // ส่วนจัดการจำนวนและราคา (ขวา)
            SingleTicketPage(
              key: _ticketPageStateKey,
              ticket: _selectedTicket,
              paymentMethods: _paymentMethods,
              onTicketSelected: _onTicketSelected,
              onCheckout: _startPaymentProcess,
              onCartChanged: _handleCartChanged, // รับค่าตะกร้ากลับมาอัปเดต
            ),
          ],
        );

      case 1: // หน้าตั๋วชุด (Package)
        return const PackageTicketPage();

      case 2: // หน้าสรุปยอด (Shift Summary)
        if (_currentUserId == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ShiftSummaryScreen(userId: _currentUserId!);

      case 3: // หน้าผู้ใช้งาน (User Profile)
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
            // ส่วนหัวด้านบน
            const HomePageHeader(),

            // พื้นที่เนื้อหาหลัก
            Expanded(
              child: Row(
                children: [
                  // เมนูแถบซ้ายสุด
                  SideMenu(
                    selectedIndex: _selectedIndex,
                    onMenuItemTapped: _onMenuItemTapped,
                  ),
                  // เนื้อหาที่เปลี่ยนไปตามเมนู
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
