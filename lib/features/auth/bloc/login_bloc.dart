import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_wallet/core/services/auth/patient_auth_service.dart';
import 'package:injectable/injectable.dart';

part 'login_event.dart';
part 'login_state.dart';

@injectable
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final PatientAuthService _authService;

  LoginBloc(this._authService) : super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(state.copyWith(status: LoginStatus.loading, error: null));
    try {
      final account = await _authService.login(event.username, event.password);
      if (account == null) {
        emit(state.copyWith(
          status: LoginStatus.failure,
          error: 'Invalid username or password.',
        ));
      } else {
        emit(state.copyWith(
          status: LoginStatus.success,
          account: account,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        error: e.toString(),
      ));
    }
  }
}
