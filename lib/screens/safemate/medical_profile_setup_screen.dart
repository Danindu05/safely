import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../core/widgets/section_card.dart';
import '../../models/medical_profile.dart';
import '../../models/user_profile.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/medical_profile_setup_viewmodel.dart';

class MedicalProfileSetupScreen extends StatelessWidget {
  const MedicalProfileSetupScreen({
    super.key,
    required this.userProfile,
    this.initialMedicalProfile,
  });

  final UserProfile userProfile;
  final MedicalProfile? initialMedicalProfile;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MedicalProfileSetupViewModel>(
      create: (_) => MedicalProfileSetupViewModel(
        profileRepository: context.read<ProfileRepository>(),
        userProfile: userProfile,
      ),
      child: _MedicalProfileSetupScreenBody(
        userProfile: userProfile,
        initialMedicalProfile: initialMedicalProfile,
      ),
    );
  }
}

class _MedicalProfileSetupScreenBody extends StatefulWidget {
  const _MedicalProfileSetupScreenBody({
    required this.userProfile,
    required this.initialMedicalProfile,
  });

  final UserProfile userProfile;
  final MedicalProfile? initialMedicalProfile;

  @override
  State<_MedicalProfileSetupScreenBody> createState() =>
      _MedicalProfileSetupScreenBodyState();
}

class _MedicalProfileSetupScreenBodyState
    extends State<_MedicalProfileSetupScreenBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.initialMedicalProfile?.fullName ?? widget.userProfile.name,
    );
    _bloodGroupController.text = widget.initialMedicalProfile?.bloodGroup ?? '';
    _allergiesController.text = widget.initialMedicalProfile?.allergies ?? '';
    _conditionsController.text =
        widget.initialMedicalProfile?.medicalConditions ?? '';
    _notesController.text = widget.initialMedicalProfile?.emergencyNotes ?? '';
    _contactNameController.text =
        widget.initialMedicalProfile?.emergencyContactName.trim().isNotEmpty ==
            true
        ? widget.initialMedicalProfile!.emergencyContactName
        : widget.userProfile.emergencyContactName;
    _contactPhoneController.text =
        widget.initialMedicalProfile?.emergencyContactPhone.trim().isNotEmpty ==
            true
        ? widget.initialMedicalProfile!.emergencyContactPhone
        : widget.userProfile.emergencyContactPhone;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submit(MedicalProfileSetupViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await viewModel.saveMedicalProfile(
      fullName: _fullNameController.text,
      bloodGroup: _bloodGroupController.text,
      allergies: _allergiesController.text,
      medicalConditions: _conditionsController.text,
      emergencyNotes: _notesController.text,
      emergencyContactName: _contactNameController.text,
      emergencyContactPhone: _contactPhoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicalProfileSetupViewModel>(
      builder:
          (
            BuildContext context,
            MedicalProfileSetupViewModel viewModel,
            Widget? child,
          ) {
            return Scaffold(
              appBar: AppBar(title: const Text('Medical profile')),
              body: ListView(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                children: <Widget>[
                  SectionCard(
                    title: 'Emergency medical information',
                    subtitle:
                        'Keep this short, accurate, and useful for guardians or first responders.',
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          AppTextField(
                            controller: _fullNameController,
                            label: 'Full name',
                            icon: Icons.person_outline,
                            validator: Validators.name,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _bloodGroupController,
                            label: 'Blood group',
                            hint: 'e.g. O+',
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _allergiesController,
                            label: 'Allergies',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _conditionsController,
                            label: 'Medical conditions',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _notesController,
                            label: 'Emergency notes',
                            maxLines: 4,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _contactNameController,
                            label: 'Emergency contact name',
                            validator: (String? value) {
                              return Validators.requiredField(
                                value,
                                'an emergency contact name',
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _contactPhoneController,
                            label: 'Emergency contact phone',
                            keyboardType: TextInputType.phone,
                            validator: Validators.phone,
                          ),
                          if (viewModel.errorMessage != null) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              viewModel.errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          PrimaryActionButton(
                            label: 'Save medical profile',
                            icon: Icons.health_and_safety_outlined,
                            isBusy: viewModel.isBusy,
                            onPressed: () => _submit(viewModel),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }
}
