import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../core/widgets/section_card.dart';
import '../../models/app_enums.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/role_selection_viewmodel.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.initialName,
  });

  final String userId;
  final String email;
  final String initialName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RoleSelectionViewModel>(
      create: (_) => RoleSelectionViewModel(
        authRepository: context.read<AuthRepository>(),
        profileRepository: context.read<ProfileRepository>(),
        userId: userId,
        email: email,
      ),
      child: _RoleSelectionScreenBody(initialName: initialName),
    );
  }
}

class _RoleSelectionScreenBody extends StatefulWidget {
  const _RoleSelectionScreenBody({required this.initialName});

  final String initialName;

  @override
  State<_RoleSelectionScreenBody> createState() =>
      _RoleSelectionScreenBodyState();
}

class _RoleSelectionScreenBodyState extends State<_RoleSelectionScreenBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(RoleSelectionViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await viewModel.saveRole(name: _nameController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleSelectionViewModel>(
      builder:
          (
            BuildContext context,
            RoleSelectionViewModel viewModel,
            Widget? child,
          ) {
            return Scaffold(
              appBar: AppBar(title: const Text('Choose your role')),
              body: ListView(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                children: <Widget>[
                  SectionCard(
                    title: 'How will you use Safely?',
                    subtitle:
                        'This decides your first setup and the tools you see first.',
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          AppTextField(
                            controller: _nameController,
                            label: 'Display name',
                            icon: Icons.person_outline,
                            validator: Validators.name,
                          ),
                          const SizedBox(height: 16),
                          ...UserRole.values.map(
                            (UserRole role) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RoleCard(
                                role: role,
                                selectedRole: viewModel.selectedRole,
                                onSelect: viewModel.selectRole,
                              ),
                            ),
                          ),
                          if (viewModel.errorMessage != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              viewModel.errorMessage!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          PrimaryActionButton(
                            label: 'Continue',
                            icon: Icons.arrow_forward,
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selectedRole,
    required this.onSelect,
  });

  final UserRole role;
  final UserRole? selectedRole;
  final ValueChanged<UserRole> onSelect;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedRole == role;
    final ThemeData theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onSelect(role),
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              role == UserRole.safemate
                  ? 'I need protection'
                  : 'I am a Guardian',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              role == UserRole.safemate
                  ? 'Fast SOS, live sharing, check-ins, medical info, and trusted guardian support.'
                  : 'Live alerts, maps, medical access, and action-ready guardian tools.',
            ),
          ],
        ),
      ),
    );
  }
}
