part of 'user_bloc.dart';

abstract class UserEvent {
  const UserEvent();
}

@freezed
abstract class UserInitialised extends UserEvent with _$UserInitialised {
  const UserInitialised._();
  const factory UserInitialised() = _UserInitialised;
}

@freezed
abstract class UserThemeToggled extends UserEvent with _$UserThemeToggled {
  const UserThemeToggled._();
  const factory UserThemeToggled() = _UserThemeToggled;
}

@freezed
abstract class UserBiometricAuthToggled extends UserEvent
    with _$UserBiometricAuthToggled {
  const UserBiometricAuthToggled._();
  const factory UserBiometricAuthToggled(bool isEnabled) =
      _UserBiometricAuthToggled;
}

@freezed
abstract class UserBiometricsSetupShown extends UserEvent with _$UserBiometricsSetupShown {
  const UserBiometricsSetupShown._();
  const factory UserBiometricsSetupShown() = _UserBiometricsSetupShown;
}

@freezed
abstract class UserDataUpdatedFromSync extends UserEvent with _$UserDataUpdatedFromSync {
  const UserDataUpdatedFromSync._();
  const factory UserDataUpdatedFromSync() = _UserDataUpdatedFromSync;
}

@freezed
abstract class UserNameUpdated extends UserEvent with _$UserNameUpdated {
  const UserNameUpdated._();
  const factory UserNameUpdated(String name) = _UserNameUpdated;
}
