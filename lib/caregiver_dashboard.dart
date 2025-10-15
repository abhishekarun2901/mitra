// caregiver_dashboard.dart (Single-Elder Implementation)

import 'package:flutter/material.dart';
import 'medicine_reminder.dart';
import 'alerts_screen.dart';
import 'health_vitals_screen.dart';
// Note: Ensure you have corresponding files: medicine_reminder.dart, alerts_screen.dart, health_vitals_screen.dart

class CaregiverDashboard extends StatelessWidget {
  const CaregiverDashboard({super.key});

  // Fixed name for the single elder being managed
  final String elderName = "The Elder";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Tools', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.blueGrey.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. MONITORING SECTION
          _buildSectionHeader(
              'Monitoring & Health for $elderName',
              Colors.teal.shade700
          ),

          CaregiverFeatureTile(
            title: 'Health Vitals Status',
            subtitle: 'View latest vitals and check-in history for $elderName.',
            icon: Icons.monitor_heart,
            color: Colors.redAccent,
            onTap: () {
              // Navigates to the Health Vitals Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HealthVitalsScreen(
                    elderName: elderName,
                  ),
                ),
              );
            },
          ),

          CaregiverFeatureTile(
            title: 'Manage Medications',
            subtitle: 'Set and check adherence for $elderName\'s reminders.',
            icon: Icons.edit_calendar,
            color: Colors.orange,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicineReminder()));
            },
          ),

          CaregiverFeatureTile(
            title: 'Manage Appointments',
            subtitle: 'View and set up appointments for $elderName.',
            icon: Icons.date_range,
            color: Colors.blueGrey,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Viewing Appointments for $elderName... (Screen not yet built)'),
              ));
            },
          ),

          CaregiverFeatureTile(
            title: 'View Smart Alerts',
            subtitle: 'Check for missed meds, inactivity warnings, or low battery alerts.',
            icon: Icons.notifications_active,
            color: Colors.amber.shade800,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsScreen()));
            },
          ),

          // 2. REMOTE ACTIONS SECTION
          const SizedBox(height: 25),
          _buildSectionHeader(
              'Remote Actions',
              Colors.deepPurple.shade700
          ),

          CaregiverFeatureTile(
            title: 'Send Custom Reminder',
            subtitle: 'Push an immediate, custom notification to $elderName\'s device.',
            icon: Icons.notifications,
            color: Colors.deepPurple,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Opening Remote Reminder Interface...'),
              ));
            },
          ),

          CaregiverFeatureTile(
            title: 'Remote SOS Activation',
            subtitle: 'Emergency: Trigger the SOS protocol on $elderName\'s device remotely.',
            icon: Icons.phone_forwarded,
            color: Colors.red.shade900,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Triggering Remote SOS...'),
              ));
            },
          ),

          // 3. SAFETY & EMERGENCY SECTION
          const SizedBox(height: 25),
          _buildSectionHeader(
              'Safety & Emergency',
              Colors.blueGrey.shade700
          ),

          CaregiverFeatureTile(
            title: 'Update Emergency Contacts',
            subtitle: 'Manage SOS contacts for $elderName.',
            icon: Icons.group,
            color: Colors.red,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Managing Emergency Contacts...')));
            },
          ),

          CaregiverFeatureTile(
            title: 'Medical Documents',
            subtitle: 'Securely access and store prescriptions or reports.',
            icon: Icons.description,
            color: Colors.brown,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accessing Document Vault...')));
            },
          ),
        ],
      ),
    );
  }

  // Reusable header for visual separation
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color
        ),
      ),
    );
  }
}

// Reusable custom widget for feature tiles
class CaregiverFeatureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CaregiverFeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}