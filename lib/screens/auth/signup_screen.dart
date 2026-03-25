import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../core/widgets/section_card.dart';
import '../../repositories/auth_repository.dart';
import '../../viewmodels/signup_viewmodel.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SignupViewModel>(
      create: (_) => SignupViewModel(context.read<AuthRepository>()),
      child: const _SignupScreenBody(),
    );
  }
}

class _SignupScreenBody extends StatefulWidget {
  const _SignupScreenBody();

  @override
  State<_SignupScreenBody> createState() => _SignupScreenBodyState();
}

class _SignupScreenBodyState extends State<_SignupScreenBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit(SignupViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final bool success = await viewModel.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignupViewModel>(
      builder:
          (BuildContext context, SignupViewModel viewModel, Widget? child) {
            return Scaffold(
              appBar: AppBar(title: const Text('Create account')),
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.pagePadding),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SectionCard(
                      title: 'Create your Safely account',
                      subtitle: 'Set up the basics, then choose your role.',
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            if (viewModel.errorMessage != null) ...<Widget>[
                              Text(
                                viewModel.errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            AppTextField(
                              controller: _nameController,
                              label: 'Name',
                              icon: Icons.person_outline,
                              validator: Validators.name,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.alternate_email,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: true,
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _confirmController,
                              label: 'Confirm password',
                              icon: Icons.lock_reset,
                              obscureText: true,
                              validator: (String? value) {
                                return Validators.confirmPassword(
                                  value,
                                  _passwordController.text,
                                );
                              },
                              onFieldSubmitted: (_) => _submit(viewModel),
                            ),
                            const SizedBox(height: 24),
                            PrimaryActionButton(
                              label: 'Create account',
                              icon: Icons.person_add_alt_1,
                              isBusy: viewModel.isBusy,
                              onPressed: () => _submit(viewModel),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }
}
