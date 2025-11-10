import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _version = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF15A19A);

    return Scaffold(
      backgroundColor: mainColor,
      appBar: AppBar(
        backgroundColor: mainColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ກ່ຽວກັບ',
          style: GoogleFonts.notoSansLao(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              // App Name
              Text(
                'ລະບົບຂາຍປີ້ສວນສະນຸກ',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansLao(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Version
              Text(
                'ເວີຊັ່ນ $_version (Build $_buildNumber)',
                style: GoogleFonts.notoSansLao(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              // Info Cards
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'ລາຍລະອຽດ',
                description: 'ແອັບພລິເຄຊັນສຳລັບການຂາຍປີ້ສວນສະນຸກ',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.build_outlined,
                title: 'ຄຸນສົມບັດ',
                description: '• ຂາຍປີ້\n• ຕິດຕາມປະຫວັດການນຳໃຊ້',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                icon: Icons.phone_outlined,
                title: 'ຕິດຕໍ່',
                description:
                    'ສຳລັບການຊ່ວຍເຫຼຶອ ແລະ ຄຳຖາມ\nກະລຸນາຕິດຕໍ່ທີມງານ\nໂທ: 20 9603 2493\nອີເມວ: niky@xangkhamtransport.com',
              ),
              const SizedBox(height: 20),
              // WhatsApp Button
              InkWell(
                onTap: () async {
                  final phoneNumber = '8562096032493';
                  final whatsappSchemeUrl = Uri.parse(
                    'whatsapp://send?phone=$phoneNumber',
                  );
                  final whatsappWebUrl = Uri.parse(
                    'https://wa.me/$phoneNumber',
                  );

                  try {
                    bool launched = await launchUrl(
                      whatsappSchemeUrl,
                      mode: LaunchMode.externalApplication,
                    );

                    if (!launched) {
                      launched = await launchUrl(
                        whatsappWebUrl,
                        mode: LaunchMode.externalApplication,
                      );
                    }

                    if (!launched) {
                      throw Exception('ບໍ່ສາມາດເປີດ WhatsApp ໄດ້');
                    }
                  } catch (e) {
                    final telUrl = Uri.parse('tel:0209603249');
                    try {
                      await launchUrl(telUrl);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'ບໍ່ສາມາດເປີດ WhatsApp ຫຼື ໂທລະສັບໄດ້',
                              style: GoogleFonts.notoSansLao(),
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.green[700],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ຕິດຕໍ່ຜ່ານ WhatsApp',
                        style: GoogleFonts.notoSansLao(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Copyright
              Text(
                '© 2025 App Developer Team\n XangKham Paseuth Co., Ltd.',
                style: GoogleFonts.notoSansLao(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'All rights reserved',
                style: GoogleFonts.notoSansLao(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF15A19A), size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.notoSansLao(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.notoSansLao(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
