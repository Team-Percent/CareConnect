part of 'scan_bloc.dart';

abstract class ScanEvent {
  const ScanEvent();
}

@freezed
abstract class ScanInitialised extends ScanEvent with _$ScanInitialised {
  const ScanInitialised._();
  const factory ScanInitialised() = _ScanInitialised;
}

@freezed
abstract class ScanButtonPressed extends ScanEvent with _$ScanButtonPressed {
  const ScanButtonPressed._();
  const factory ScanButtonPressed({
    @Default(ScanMode.images) ScanMode mode,
    @Default(5) int maxPages,
  }) = _ScanButtonPressed;
}

@freezed
abstract class DocumentImported extends ScanEvent with _$DocumentImported {
  const DocumentImported._();
  const factory DocumentImported({
    required String filePath,
  }) = _DocumentImported;
}

@freezed
abstract class ScanSessionChangedProgress extends ScanEvent with _$ScanSessionChangedProgress {
  const ScanSessionChangedProgress._();
  const factory ScanSessionChangedProgress({
    required ProcessingSession session,
  }) = _ScanSessionChangedProgress;
}

@freezed
abstract class ScanSessionCleared extends ScanEvent with _$ScanSessionCleared {
  const ScanSessionCleared._();
  const factory ScanSessionCleared({
    required ProcessingSession session,
  }) = _ScanSessionCleared;
}

enum ScanMode {
  images,
  pdf,
}

@freezed
abstract class ScanSessionActivated extends ScanEvent with _$ScanSessionActivated {
  const ScanSessionActivated._();
  const factory ScanSessionActivated({
    required String sessionId,
  }) = _ScanSessionActivated;
}

@freezed
abstract class ScanMappingInitiated extends ScanEvent with _$ScanMappingInitiated {
  const ScanMappingInitiated._();
  const factory ScanMappingInitiated({required String sessionId}) =
      _ScanMappingInitiated;
}

@freezed
abstract class ScanResourceChanged extends ScanEvent with _$ScanResourceChanged {
  const ScanResourceChanged._();
  const factory ScanResourceChanged({
    required String sessionId,
    required int index,
    required String propertyKey,
    required String newValue,
    bool? isDraftPatient,
    bool? isDraftEncounter,
  }) = _ScanResourceChanged;
}

@freezed
abstract class ScanResourceRemoved extends ScanEvent with _$ScanResourceRemoved {
  const ScanResourceRemoved._();
  const factory ScanResourceRemoved(
      {required String sessionId, required int index}) = _ScanResourceRemoved;
}

@freezed
abstract class ScanResourceCreationInitiated extends ScanEvent with _$ScanResourceCreationInitiated {
  const ScanResourceCreationInitiated._();
  const factory ScanResourceCreationInitiated({required String sessionId}) =
      _ScanResourceCreationInitiated;
}

@freezed
abstract class ScanNotificationAcknowledged extends ScanEvent with _$ScanNotificationAcknowledged {
  const ScanNotificationAcknowledged._();
  const factory ScanNotificationAcknowledged() = _ScanNotificationAcknowledged;
}

@freezed
abstract class ScanMappingCancelled extends ScanEvent with _$ScanMappingCancelled {
  const ScanMappingCancelled._();
  const factory ScanMappingCancelled({required String sessionId}) =
      _ScanMappingCancelled;
}

@freezed
abstract class ScanResourcesAdded extends ScanEvent with _$ScanResourcesAdded {
  const ScanResourcesAdded._();
  const factory ScanResourcesAdded({
    required String sessionId,
    required List<String> resourceTypes,
  }) = _ScanResourcesAdded;
}

@freezed
abstract class ScanEncounterAttached extends ScanEvent with _$ScanEncounterAttached {
  const ScanEncounterAttached._();
  const factory ScanEncounterAttached({
    required String sessionId,
    required StagedPatient patient,
    required StagedEncounter encounter,
  }) = _ScanEncounterAttached;
}

@freezed
abstract class ScanProcessRemainingResources extends ScanEvent with _$ScanProcessRemainingResources {
  const ScanProcessRemainingResources._();
  const factory ScanProcessRemainingResources({
    required String sessionId,
  }) = _ScanProcessRemainingResources;
}

@freezed
abstract class ScanDocumentAttached extends ScanEvent with _$ScanDocumentAttached {
  const ScanDocumentAttached._();
  const factory ScanDocumentAttached({
    required String sessionId,
  }) = _ScanDocumentAttached;
}
