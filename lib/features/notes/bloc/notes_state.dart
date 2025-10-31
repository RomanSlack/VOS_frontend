import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/notes_models.dart';

abstract class NotesState extends Equatable {
  const NotesState();

  @override
  List<Object?> get props => [];
}

// Initial state
class NotesInitial extends NotesState {
  const NotesInitial();
}

// Loading state
class NotesLoading extends NotesState {
  const NotesLoading();
}

// Loaded list of notes
class NotesLoaded extends NotesState {
  final List<Note> notes;
  final int totalCount;
  final bool hasMore;
  final int currentOffset;

  const NotesLoaded({
    required this.notes,
    required this.totalCount,
    required this.hasMore,
    this.currentOffset = 0,
  });

  @override
  List<Object?> get props => [notes, totalCount, hasMore, currentOffset];

  NotesLoaded copyWith({
    List<Note>? notes,
    int? totalCount,
    bool? hasMore,
    int? currentOffset,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }
}

// Single note loaded
class NoteDetailLoaded extends NotesState {
  final Note note;

  const NoteDetailLoaded(this.note);

  @override
  List<Object?> get props => [note];
}

// Search results loaded
class NotesSearchResults extends NotesState {
  final List<Note> notes;
  final String query;
  final int count;

  const NotesSearchResults({
    required this.notes,
    required this.query,
    required this.count,
  });

  @override
  List<Object?> get props => [notes, query, count];
}

// Operation success
class NotesOperationSuccess extends NotesState {
  final String message;
  final List<Note> notes;

  const NotesOperationSuccess({
    required this.message,
    required this.notes,
  });

  @override
  List<Object?> get props => [message, notes];
}

// Error state
class NotesError extends NotesState {
  final String message;
  final String? details;

  const NotesError(this.message, {this.details});

  @override
  List<Object?> get props => [message, details];
}
