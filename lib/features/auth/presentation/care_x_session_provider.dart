import 'dart:async';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_wallet/core/di/injection.dart';
import 'package:health_wallet/core/navigation/app_router.dart';
import 'package:health_wallet/core/services/auth/patient_auth_service.dart';

/// State for the patient session (patient info).
class CareXSessionState {
  final bool isLoading;
  final String? error;
  final PatientAccount? account;

  const CareXSessionState({
    this.isLoading = false,
    this.error,
    this.account,
  });

  CareXSessionState copyWith({
    bool? isLoading,
    String? error,
    PatientAccount? account,
  }) =>
      CareXSessionState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        account: account ?? this.account,
      );

  double get trustScore {
    double score = 0;
    if (account != null) score += 50;
    return score;
  }
}

/// Cubit for loading session data scoped to the logged-in patient.
class CareXSessionCubit extends Cubit<CareXSessionState> {
  final PatientAuthService _authService;

  CareXSessionCubit(this._authService) : super(const CareXSessionState());

  Future<void> loadSession() async {
    emit(state.copyWith(isLoading: true));
    try {
      final account = await _authService.getCurrentAccount();
      if (account == null) {
        emit(state.copyWith(isLoading: false, error: 'Not logged in'));
        return;
      }

      emit(state.copyWith(
        isLoading: false,
        account: account,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> logout(BuildContext context) async {
    await _authService.logout();
    if (context.mounted) {
      context.router.replace(const LoginRoute());
    }
  }

}

/// Provider widget that wraps the entire portal with the session cubit.
class CareXSessionProvider extends StatelessWidget {
  final Widget child;
  const CareXSessionProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CareXSessionCubit(
        getIt<PatientAuthService>(),
      )..loadSession(),
      child: child,
    );
  }
}
