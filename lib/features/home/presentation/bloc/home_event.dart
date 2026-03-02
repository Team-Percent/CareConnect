part of 'home_bloc.dart';

abstract class HomeEvent {
  const HomeEvent();
}

@freezed
abstract class HomeInitialised extends HomeEvent with _$HomeInitialised {
  const HomeInitialised._();
  const factory HomeInitialised() = _HomeInitialised;
}

@freezed
abstract class HomeSourceChanged extends HomeEvent with _$HomeSourceChanged {
  const HomeSourceChanged._();
  const factory HomeSourceChanged(
    String source, {
    List<String>? patientSourceIds,
  }) = _HomeSourceChanged;
}

@freezed
abstract class HomeEditModeChanged extends HomeEvent
    with _$HomeEditModeChanged {
  const HomeEditModeChanged._();
  const factory HomeEditModeChanged(bool editMode) = _HomeEditModeChanged;
}

@freezed
abstract class HomeRecordsReordered extends HomeEvent
    with _$HomeRecordsReordered {
  const HomeRecordsReordered._();
  const factory HomeRecordsReordered(int oldIndex, int newIndex) =
      _HomeRecordsReordered;
}

@freezed
abstract class HomeVitalsReordered extends HomeEvent
    with _$HomeVitalsReordered {
  const HomeVitalsReordered._();
  const factory HomeVitalsReordered(int oldIndex, int newIndex) =
      _HomeVitalsReordered;
}

@freezed
abstract class HomeVitalsFiltersChanged extends HomeEvent
    with _$HomeVitalsFiltersChanged {
  const HomeVitalsFiltersChanged._();
  const factory HomeVitalsFiltersChanged(Map<PatientVitalType, bool> filters) =
      _HomeVitalsFiltersChanged;
}

@freezed
abstract class HomeRecordsFiltersChanged extends HomeEvent
    with _$HomeRecordsFiltersChanged {
  const HomeRecordsFiltersChanged._();
  const factory HomeRecordsFiltersChanged(
    Map<HomeRecordsCategory, bool> filters,
  ) = _HomeRecordsFiltersChanged;
}

@freezed
abstract class HomeVitalsExpansionToggled extends HomeEvent
    with _$HomeVitalsExpansionToggled {
  const HomeVitalsExpansionToggled._();
  const factory HomeVitalsExpansionToggled() = _HomeVitalsExpansionToggled;
}

@freezed
abstract class HomeRefreshPreservingOrder extends HomeEvent
    with _$HomeRefreshPreservingOrder {
  const HomeRefreshPreservingOrder._();
  const factory HomeRefreshPreservingOrder() = _HomeRefreshPreservingOrder;
}

@freezed
abstract class HomeSourceLabelUpdated extends HomeEvent
    with _$HomeSourceLabelUpdated {
  const HomeSourceLabelUpdated._();
  const factory HomeSourceLabelUpdated(String sourceId, String newLabel) =
      _HomeSourceLabelUpdated;
}

@freezed
abstract class HomeVitalsRefreshed extends HomeEvent
    with _$HomeVitalsRefreshed {
  const HomeVitalsRefreshed._();
  const factory HomeVitalsRefreshed() = _HomeVitalsRefreshed;
}

@freezed
abstract class HomeSourceDeleted extends HomeEvent with _$HomeSourceDeleted {
  const HomeSourceDeleted._();
  const factory HomeSourceDeleted(
    String sourceId, {
    List<String>? patientSourceIds,
  }) = _HomeSourceDeleted;
}
