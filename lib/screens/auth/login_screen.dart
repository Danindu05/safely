import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_action_button.dart';
import '../../core/widgets/section_card.dart';
import '../../repositories/auth_repository.dart';
import '../../viewmodels/login_viewmodel.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>(
      create: (_) => LoginViewModel(context.read<AuthRepository>()),
      child: const _LoginScreenBody(),
    );
  }
}

class _LoginScreenBody extends StatefulWidget {
  const _LoginScreenBody();

  @override
  State<_LoginScreenBody> createState() => _LoginScreenBodyState();
}

class _LoginScreenBodyState extends State<_LoginScreenBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(LoginViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final bool success = await viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (BuildContext context, LoginViewModel viewModel, Widget? child) {
        return Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SectionCard(
                  title: 'Sign in',
                  subtitle: 'Calm access when it matters.',
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          onFieldSubmitted: (_) => _submit(viewModel),
                        ),
                        const SizedBox(height: 24),
                        PrimaryActionButton(
                          label: 'Sign in',
                          icon: Icons.login,
                          isBusy: viewModel.isBusy,
                          onPressed: () => _submit(viewModel),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                          child: const Text('Create a new account'),
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
