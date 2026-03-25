import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../core/widgets/section_card.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Safely')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        children: <Widget>[
          Text(
            'Protection that stays practical.',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Safely helps a protected person stay connected to trusted guardians during emergencies, check-ins, and live sharing moments.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const SectionCard(
            title: 'What gets shared',
            subtitle:
                'Only the information needed to help fast in a real situation.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('• SOS alerts and alert status'),
                SizedBox(height: 8),
                Text('• Live location during emergency or manual sharing'),
                SizedBox(height: 8),
                Text('• Battery warnings, check-ins, and medical information'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: 'When guardians are notified',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('• SOS is activated'),
                SizedBox(height: 8),
                Text('• Battery falls below configured thresholds'),
                SizedBox(height: 8),
                Text('• Unsafe geofence events happen'),
                SizedBox(height: 8),
                Text('• Manual check-ins are sent'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryActionButton(
            label: 'Get started',
            icon: Icons.arrow_forward,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
