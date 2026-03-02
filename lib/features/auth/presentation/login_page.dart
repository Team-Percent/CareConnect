import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_wallet/core/di/injection.dart';
import 'package:health_wallet/core/navigation/app_router.dart';
import 'package:health_wallet/core/theme/app_insets.dart';
import 'package:health_wallet/core/theme/app_text_style.dart';
import 'package:health_wallet/core/utils/build_context_extension.dart';
import 'package:health_wallet/features/auth/bloc/login_bloc.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoginBloc>(),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (ctx, state) {
          if (state.status == LoginStatus.success) {
            ctx.router.replace(const DashboardRoute());
          }
        },
        child: Scaffold(
          backgroundColor: context.colorScheme.surface,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Insets.normal,
                  vertical: Insets.large,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Brand header ────────────────────────────────────────
                      const SizedBox(height: Insets.large),
                      Icon(
                        Icons.health_and_safety_outlined,
                        size: 64,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(height: Insets.medium),
                      Text(
                        'C.A.R.E.-X',
                        textAlign: TextAlign.center,
                        style: AppTextStyle.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: Insets.extraSmall),
                      Text(
                        'Patient Portal',
                        textAlign: TextAlign.center,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: context.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: Insets.large),

                      // ── Card ─────────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(Insets.medium),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: context.isDarkMode
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sign In',
                              style: AppTextStyle.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: Insets.medium),

                            // Username
                            TextFormField(
                              controller: _usernameCtrl,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.username],
                              style: AppTextStyle.bodyMedium.copyWith(
                                color: context.colorScheme.onSurface,
                              ),
                              decoration: _inputDecoration(
                                context,
                                label: 'Username',
                                hint: 'patient@care.x',
                                icon: Icons.person_outline,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter your username'
                                  : null,
                            ),
                            const SizedBox(height: Insets.smallNormal),

                            // Password
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              style: AppTextStyle.bodyMedium.copyWith(
                                color: context.colorScheme.onSurface,
                              ),
                              decoration: _inputDecoration(
                                context,
                                label: 'Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: context.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter your password'
                                  : null,
                            ),
                            const SizedBox(height: Insets.medium),

                            // Error message
                            BlocBuilder<LoginBloc, LoginState>(
                              buildWhen: (p, c) => p.error != c.error,
                              builder: (ctx, state) {
                                if (state.error == null) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: Insets.small),
                                  child: Text(
                                    state.error!,
                                    style: AppTextStyle.bodySmall.copyWith(
                                      color: context.colorScheme.error,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),

                            // Login button
                            BlocBuilder<LoginBloc, LoginState>(
                              buildWhen: (p, c) => p.status != c.status,
                              builder: (ctx, state) {
                                final loading =
                                    state.status == LoginStatus.loading;
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        context.colorScheme.primary,
                                    foregroundColor:
                                        context.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: Insets.smallNormal),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: loading
                                      ? null
                                      : () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            ctx.read<LoginBloc>().add(
                                                  LoginSubmitted(
                                                    username:
                                                        _usernameCtrl.text,
                                                    password:
                                                        _passwordCtrl.text,
                                                  ),
                                                );
                                          }
                                        },
                                  child: loading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                context.colorScheme.onPrimary,
                                          ),
                                        )
                                      : Text(
                                          'Login',
                                          style:
                                              AppTextStyle.labelLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // ── Hint text ─────────────────────────────────────────────
                      const SizedBox(height: Insets.medium),
                      Text(
                        'Demo: patient@care.x / password123',
                        textAlign: TextAlign.center,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: context.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final borderColor = context.isDarkMode
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.1);
    final activeBorderColor = context.colorScheme.primary;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon,
          color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
      labelStyle: AppTextStyle.bodySmall.copyWith(
        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      hintStyle: AppTextStyle.bodySmall.copyWith(
        color: context.colorScheme.onSurface.withValues(alpha: 0.25),
      ),
      filled: true,
      fillColor: context.isDarkMode
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: activeBorderColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colorScheme.error),
      ),
    );
  }
}
