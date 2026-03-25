import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/section_card.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/safemate_profile_viewmodel.dart';

class SafemateProfileScreen extends StatelessWidget {
  const SafemateProfileScreen({super.key, required this.safemateId});

  final String safemateId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SafemateProfileViewModel>(
      create: (_) => SafemateProfileViewModel(
        profileRepository: context.read<ProfileRepository>(),
        alertRepository: context.read<AlertRepository>(),
        safemateId: safemateId,
      ),
      child: const _SafemateProfileScreenBody(),
    );
  }
}

class _SafemateProfileScreenBody extends StatelessWidget {
  const _SafemateProfileScreenBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<SafemateProfileViewModel>(
      builder: (BuildContext context, SafemateProfileViewModel viewModel, Widget? child) {
        final profile = viewModel.profile;
        final medical = viewModel.medicalProfile;

        return Scaffold(
          appBar: AppBar(title: const Text('Safemate profile')),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: <Widget>[
              if (profile == null)
                const EmptyStateCard(
                  icon: Icons.person_off_outlined,
                  title: 'Profile unavailable',
                  message: 'This Safemate profile could not be loaded.',
                )
              else ...<Widget>[
                SectionCard(
                  title: profile.name,
                  subtitle: profile.email,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Battery: ${profile.batteryLevel ?? '--'}%'),
                      const SizedBox(height: 6),
                      Text(
                        'Emergency active: ${profile.isEmergencyActive ? 'Yes' : 'No'}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Last seen: ${profile.lastSeenAt == null ? 'Unknown' : DateTimeFormatter.formatShort(profile.lastSeenAt!)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (medical != null)
                  SectionCard(
                    title: 'Medical information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Blood group: ${medical.bloodGroup}'),
                        const SizedBox(height: 6),
                        Text('Allergies: ${medical.allergies}'),
                        const SizedBox(height: 6),
                        Text('Conditions: ${medical.medicalConditions}'),
                        const SizedBox(height: 6),
                        Text(
                          'Emergency contact: ${medical.emergencyContactName}',
                        ),
                        const SizedBox(height: 6),
                        Text(medical.emergencyContactPhone),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Recent history summary',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: viewModel.alerts.isEmpty
                        ? const <Widget>[Text('No recent alerts.')]
                        : viewModel.alerts
                              .map(
                                (alert) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    '${alert.title} • ${DateTimeFormatter.formatShort(alert.timestamp)}',
                                  ),
                                ),
                              )
                              .toList(growable: false),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
