import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../core/widgets/section_card.dart';
import '../../repositories/profile_repository.dart';
import '../../viewmodels/guardians_viewmodel.dart';

class GuardiansScreen extends StatelessWidget {
  const GuardiansScreen({super.key, required this.safemateId});

  final String safemateId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GuardiansViewModel>(
      create: (_) => GuardiansViewModel(
        profileRepository: context.read<ProfileRepository>(),
        safemateId: safemateId,
      ),
      child: const _GuardiansScreenBody(),
    );
  }
}

class _GuardiansScreenBody extends StatefulWidget {
  const _GuardiansScreenBody();

  @override
  State<_GuardiansScreenBody> createState() => _GuardiansScreenBodyState();
}

class _GuardiansScreenBodyState extends State<_GuardiansScreenBody> {
  final TextEditingController _guardianIdController = TextEditingController();

  @override
  void dispose() {
    _guardianIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GuardiansViewModel>(
      builder: (BuildContext context, GuardiansViewModel viewModel, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Guardians')),
          body: ListView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            children: <Widget>[
              SectionCard(
                title: 'Add guardian by UID',
                subtitle:
                    'For now, guardians can share their user ID from the Guardian dashboard.',
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _guardianIdController,
                      decoration: const InputDecoration(
                        labelText: 'Guardian ID',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryActionButton(
                      label: 'Link guardian',
                      icon: Icons.person_add_alt_1,
                      isBusy: viewModel.isBusy,
                      onPressed: () async {
                        await viewModel.addGuardian(_guardianIdController.text);
                        if (viewModel.errorMessage == null && mounted) {
                          _guardianIdController.clear();
                        }
                      },
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
                    if (viewModel.infoMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(viewModel.infoMessage!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (viewModel.guardians.isEmpty)
                const EmptyStateCard(
                  icon: Icons.groups_2_outlined,
                  title: 'No guardians linked',
                  message:
                      'Link a trusted person so they can receive alerts, see live location, and view emergency info.',
                )
              else
                ...viewModel.guardians.map(
                  (guardian) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      title: guardian.name,
                      subtitle: guardian.email,
                      trailing: IconButton(
                        onPressed: () => viewModel.removeGuardian(guardian.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                      child: SelectableText(guardian.id),
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
