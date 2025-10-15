import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_details_screen.dart';
import 'chat_screen.dart';
import 'brain_games_screen.dart';
import 'health_vitals_screen.dart';
import 'emergency_contact.dart';

// --- Data Model for Features ---
class CareFeature {
  final String title;
  final IconData icon;
  final Color color;
  final Function(BuildContext) onTap;

  CareFeature({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// --- Home Screen Widget ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _emergencyContactName;
  String? _emergencyContactPhone;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  // Load emergency contact from Firebase
  Future<void> _loadEmergencyContact() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          setState(() {
            _userName = data?['name'];
            _emergencyContactName = data?['emergencyContact']?['name'];
            _emergencyContactPhone = data?['emergencyContact']?['phone'];
          });
        }
      }
    } catch (e) {
      print('Error loading emergency contact: $e');
    }
  }

  // Send SMS Alert
  Future<void> _sendSMSAlert() async {
    if (_emergencyContactPhone == null || _emergencyContactPhone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contact found. Please update your profile.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Emergency Alert?'),
        content: Text(
          'This will send an SMS to $_emergencyContactName ($_emergencyContactPhone) indicating you need help.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Create SMS message
      final message = Uri.encodeComponent(
        'EMERGENCY ALERT: ${_userName ?? "Your elder"} needs immediate assistance. Please check on them urgently. This is an automated alert from Mitra Elderly Companion app.',
      );

      // Create SMS URI
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: _emergencyContactPhone,
        queryParameters: {'body': message},
      );

      // Launch SMS app
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening SMS app to send emergency alert...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw 'Could not launch SMS app';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send SMS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void handleFeatureTap(BuildContext context, String featureTitle) {
    switch (featureTitle) {
      case 'Chatbot':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(title: 'Chat'),
          ),
        );
        break;

      case 'Appointment':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$featureTitle clicked! (Coming Soon)')),
        );
        break;
      case 'Add Medicine':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$featureTitle clicked! (Coming Soon)')),
        );
        break;
      case 'Contact Relatives':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmergencyContactScreen(),
          ),
        );
        break;
      case 'Emergency':
        _sendSMSAlert();
        break;
      case 'Health Tracker':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HealthVitalsScreen(elderName: "John"),
          ),
        );
        break;
      case 'Brain Games':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BrainGamesScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unhandled feature: $featureTitle')),
        );
    }
  }

  List<CareFeature> get _features => [
    // 1. Talk to Mitra Feature
    CareFeature(
        title: 'Chatbot',
        icon: Icons.chat_bubble_outline,
        color: Colors.green.shade600,
        onTap: (context) => handleFeatureTap(context, 'Chatbot')),

    // 2. Elderly Care Features
    CareFeature(
        title: 'Appointment',
        icon: Icons.person_pin_circle,
        color: Colors.deepPurple,
        onTap: (context) => handleFeatureTap(context, 'Appointment')),
    CareFeature(
        title: 'Add Medicine',
        icon: Icons.medical_services,
        color: Colors.orange,
        onTap: (context) => handleFeatureTap(context, 'Add Medicine')),
    CareFeature(
        title: 'Locate Nearby',
        icon: Icons.local_hospital,
        color: Colors.teal.shade800,
        onTap: (context) => handleFeatureTap(context, 'Locate Nearby')),
    CareFeature(
        title: 'Contact Relatives',
        icon: Icons.accessibility_new,
        color: Colors.pink.shade700,
        onTap: (context) => handleFeatureTap(context, 'Contact Relatives')),
    CareFeature(
        title: 'Emergency',
        icon: Icons.warning,
        color: Colors.red.shade700,
        onTap: (context) => handleFeatureTap(context, 'Emergency')),
    CareFeature(
        title: 'Brain Games',
        icon: Icons.psychology,
        color: Colors.purple.shade600,
        onTap: (context) => handleFeatureTap(context, 'Brain Games')),

    // 3. Elderly Companion Features
    CareFeature(
        title: 'Health Tracker',
        icon: Icons.monitor_heart,
        color: Colors.blue.shade700,
        onTap: (context) => handleFeatureTap(context, 'Health Tracker')),
  ];

  @override
  Widget build(BuildContext context) {
    final List<CareFeature> talkToMitraFeatures = _features.sublist(0, 1);
    final List<CareFeature> elderlyCareFeatures = _features.sublist(1, 7);
    final List<CareFeature> elderlyCompanionFeatures = _features.sublist(7);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elderly Companion',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        actions: [
          // Navigation to the ProfileDetailsScreen for editing
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProfileDetailsScreen()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: _sendSMSAlert),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Talk to Mitra Section
            _buildSectionHeader('Talk to Mitra'),
            _buildFeatureGrid(talkToMitraFeatures),

            const SizedBox(height: 30),

            // 2. Elderly Care Section
            _buildSectionHeader('Elderly Care'),
            _buildFeatureGrid(elderlyCareFeatures),

            const SizedBox(height: 30),

            // 3. Elderly Companion Section
            _buildSectionHeader('Elderly Companion'),
            _buildFeatureGrid(elderlyCompanionFeatures),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(title,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }

  Widget _buildFeatureGrid(List<CareFeature> features) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.70,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return CareFeatureButton(feature: features[index]);
      },
    );
  }
}

// --- Custom Widget for Feature Button ---
class CareFeatureButton extends StatelessWidget {
  final CareFeature feature;

  const CareFeatureButton({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => feature.onTap(context),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: feature.color,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: feature.color.withValues(),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(feature.icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              feature.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}