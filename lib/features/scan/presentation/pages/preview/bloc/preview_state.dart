part of 'preview_bloc.dart';

@freezed
abstract class PreviewState with _$PreviewState {
  const factory PreviewState({
    @Default(0) int currentPageIndex,
  }) = _PreviewState;
}
