part of 'records_bloc.dart';

abstract class RecordsEvent {
  const RecordsEvent();
}

@freezed
abstract class RecordsInitialised extends RecordsEvent
    with _$RecordsInitialised {
  const RecordsInitialised._();
  const factory RecordsInitialised() = _RecordsInitialised;
}

@freezed
abstract class RecordsLoadMore extends RecordsEvent with _$RecordsLoadMore {
  const RecordsLoadMore._();
  const factory RecordsLoadMore() = _RecordsLoadMore;
}

@freezed
abstract class RecordsSourceChanged extends RecordsEvent
    with _$RecordsSourceChanged {
  const RecordsSourceChanged._();
  const factory RecordsSourceChanged(
    String? sourceId, {
    List<String>? sourceIds,
  }) = _RecordsSourceChanged;
}

@freezed
abstract class RecordsFiltersApplied extends RecordsEvent
    with _$RecordsFiltersApplied {
  const RecordsFiltersApplied._();
  const factory RecordsFiltersApplied(List<FhirType> filters) =
      _RecordsFiltersApplied;
}

@freezed
abstract class RecordsFilterRemoved extends RecordsEvent
    with _$RecordsFilterRemoved {
  const RecordsFilterRemoved._();
  const factory RecordsFilterRemoved(FhirType filter) = _RecordsFilterRemoved;
}

@freezed
abstract class RecordDetailLoaded extends RecordsEvent
    with _$RecordDetailLoaded {
  const RecordDetailLoaded._();
  const factory RecordDetailLoaded(IFhirResource resource) =
      _RecordsDetailLoaded;
}

@freezed
abstract class LoadDemoData extends RecordsEvent with _$LoadDemoData {
  const LoadDemoData._();
  const factory LoadDemoData() = _LoadDemoData;
}

@freezed
abstract class ClearDemoData extends RecordsEvent with _$ClearDemoData {
  const ClearDemoData._();
  const factory ClearDemoData() = _ClearDemoData;
}

@freezed
abstract class RecordsSearch extends RecordsEvent with _$RecordsSearch {
  const RecordsSearch._();
  const factory RecordsSearch(String query) = _RecordsSearch;
}

@freezed
abstract class RecordsSearchExecuted extends RecordsEvent
    with _$RecordsSearchExecuted {
  const RecordsSearchExecuted._();
  const factory RecordsSearchExecuted(String query) = _RecordsSearchExecuted;
}

@freezed
abstract class RecordsSharePressed extends RecordsEvent
    with _$RecordsSharePressed {
  const RecordsSharePressed._();
  const factory RecordsSharePressed() = _RecordsSharePressed;
}
