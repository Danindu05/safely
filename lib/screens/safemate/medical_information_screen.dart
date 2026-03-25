import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/section_card.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/medical_information_viewmodel.dart';
import 'medical_profile_setup_screen.dart';

class MedicalInformationScreen extends StatelessWidget {
  const MedicalInformationScreen({
    super.key,
    required this.userId,
    required this.title,
    this.editable = false,
    this.userProfile,
  });

  final String userId;
  final String title;
  final bool editable;
  final UserProfile? userProfile;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MedicalInformationViewModel>(
      create: (_) => MedicalInformationViewModel(
        profileRepository: context.read<ProfileRepository>(),
        userId: userId,
      ),
      child: _MedicalInformationScreenBody(
        title: title,
        editable: editable,
        userProfile: userProfile,
      ),
    );
  }
}

class _MedicalInformationScreenBody extends StatelessWidget {
  const _MedicalInformationScreenBody({
    required this.title,
    required this.editable,
    required this.userProfile,
  });

  final String title;
  final bool editable;
  final UserProfile? userProfile;

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicalInformationViewModel>(
      builder: (BuildContext context, MedicalInformationViewModel viewModel, Widget? child) {
        final medical = viewModel.medicalProfile;

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: <Widget>[
              if (editable && userProfile != null)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MedicalProfileSetupScreen(
                          userProfile: userProfile!,
                          initialMedicalProfile: medical,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: <Widget>[
              if (medical == null)
                const EmptyStateCard(
                  icon: Icons.medical_information_outlined,
                  title: 'No medical profile yet',
                  message:
                      'Add blood group, allergies, conditions, and emergency contacts from the Safemate setup flow.',
                )
              else ...<Widget>[
                SectionCard(
                  title: medical.fullName,
                  subtitle: 'Emergency medical overview',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Blood group: ${medical.bloodGroup.isEmpty ? 'Not set' : medical.bloodGroup}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Allergies: ${medical.allergies.isEmpty ? 'None recorded' : medical.allergies}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conditions: ${medical.medicalConditions.isEmpty ? 'None recorded' : medical.medicalConditions}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Emergency notes: ${medical.emergencyNotes.isEmpty ? 'None' : medical.emergencyNotes}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Emergency contact',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(medical.emergencyContactName),
                      const SizedBox(height: 6),
                      Text(medical.emergencyContactPhone),
                    ],
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
