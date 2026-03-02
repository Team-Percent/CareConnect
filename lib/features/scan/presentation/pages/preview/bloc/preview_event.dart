part of 'preview_bloc.dart';

abstract class PreviewEvent {
  const PreviewEvent();
}

@freezed
abstract class PreviewPageChanged extends PreviewEvent
    with _$PreviewPageChanged {
  const PreviewPageChanged._();
  const factory PreviewPageChanged({required int pageIndex}) =
      _PreviewPageChanged;
}

@freezed
abstract class PreviewInitialized extends PreviewEvent
    with _$PreviewInitialized {
  const PreviewInitialized._();
  const factory PreviewInitialized({required int initialPageIndex}) =
      _PreviewInitialized;
}
