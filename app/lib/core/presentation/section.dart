/// The load state of one independently-loading part of a screen (the
/// balance panel, a transaction list). A screen switches over it
/// exhaustively, so adding a state is a compile error until every screen
/// handles it.
///
/// A refresh keeps the section [SectionLoaded]: shimmer is only for a first
/// load or a retry after an error.
sealed class Section<T> {
  const Section();
}

final class SectionLoading<T> extends Section<T> {
  const SectionLoading();
}

final class SectionLoaded<T> extends Section<T> {
  const SectionLoaded(this.data);

  final T data;
}

final class SectionFailed<T> extends Section<T> {
  const SectionFailed(this.message);

  /// Already user-facing, e.g. "Check the backend is running."
  final String message;
}
