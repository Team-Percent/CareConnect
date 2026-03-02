part of 'record_attachments_bloc.dart';

abstract class RecordAttachmentsEvent {
  const RecordAttachmentsEvent();
}

@freezed
abstract class RecordAttachmentsInitialised extends RecordAttachmentsEvent with _$RecordAttachmentsInitialised {
  const RecordAttachmentsInitialised._();
  const factory RecordAttachmentsInitialised({
    required IFhirResource resource,
  }) = _RecordAttachmentsInitialised;
}

@freezed
abstract class RecordAttachmentsFileAttached extends RecordAttachmentsEvent with _$RecordAttachmentsFileAttached {
  const RecordAttachmentsFileAttached._();
  const factory RecordAttachmentsFileAttached(File file) =
      _RecordAttachmentsFileAttached;
}

@freezed
abstract class RecordAttachmentsFileDeleted extends RecordAttachmentsEvent with _$RecordAttachmentsFileDeleted {
  const RecordAttachmentsFileDeleted._();
  const factory RecordAttachmentsFileDeleted(IFhirResource attachment) =
      _RecordAttachmentsFileDeleted;
}
