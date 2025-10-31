import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/api/notes_api.dart';
import 'package:vos_app/core/models/notes_models.dart';
import 'package:vos_app/features/notes/bloc/notes_event.dart';
import 'package:vos_app/features/notes/bloc/notes_state.dart';

class NotesBloc extends Bloc<NotesBlocEvent, NotesState> {
  final NotesToolHelper notesApi;
  final String userId; // For created_by field

  NotesBloc(this.notesApi, this.userId) : super(const NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<LoadNote>(_onLoadNote);
    on<CreateNote>(_onCreateNote);
    on<UpdateNote>(_onUpdateNote);
    on<DeleteNote>(_onDeleteNote);
    on<SearchNotes>(_onSearchNotes);
    on<ArchiveNote>(_onArchiveNote);
    on<PinNote>(_onPinNote);
    on<RefreshNotes>(_onRefreshNotes);
    on<NoteAdded>(_onNoteAdded);
    on<NoteUpdated>(_onNoteUpdated);
    on<NoteDeleted>(_onNoteDeleted);
    on<NoteArchived>(_onNoteArchived);
  }

  Future<void> _onLoadNotes(
    LoadNotes event,
    Emitter<NotesState> emit,
  ) async {
    try {
      emit(const NotesLoading());

      final response = await notesApi.listNotes(
        folder: event.folder,
        tags: event.tags,
        isPinned: event.isPinned,
        isArchived: event.isArchived ?? false,
        createdBy: userId,
        limit: event.limit ?? 50,
        offset: event.offset ?? 0,
        sortBy: event.sortBy ?? 'updated_at',
        sortOrder: event.sortOrder ?? 'desc',
      );

      if (response.status == 'success' && response.result != null) {
        final result = response.result!;
        final notesData = result['notes'] as List?;
        final notes = notesData
                ?.map((e) => Note.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        final totalCount = result['total_count'] as int? ?? 0;
        final hasMore = result['has_more'] as bool? ?? false;
        final offset = result['offset'] as int? ?? 0;

        emit(NotesLoaded(
          notes: notes,
          totalCount: totalCount,
          hasMore: hasMore,
          currentOffset: offset,
        ));
      } else {
        emit(NotesError(
          'Failed to load notes',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(NotesError('Error loading notes', details: e.toString()));
    }
  }

  Future<void> _onLoadNote(
    LoadNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      emit(const NotesLoading());

      final response = await notesApi.getNote(
        noteId: event.noteId,
        createdBy: userId,
      );

      if (response.status == 'success' && response.result != null) {
        final note = Note.fromJson(response.result!);
        emit(NoteDetailLoaded(note));
      } else {
        emit(NotesError(
          'Failed to load note',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(NotesError('Error loading note', details: e.toString()));
    }
  }

  Future<void> _onCreateNote(
    CreateNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! NotesLoaded) {
        emit(const NotesLoading());
      }

      final response = await notesApi.createNote(event.request);

      if (response.status == 'success' && response.result != null) {
        // Reload notes to get the updated list
        add(const RefreshNotes());

        emit(NotesOperationSuccess(
          message: 'Note created successfully',
          notes: currentState is NotesLoaded ? currentState.notes : [],
        ));
      } else {
        emit(NotesError(
          'Failed to create note',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(NotesError('Error creating note', details: e.toString()));
    }
  }

  Future<void> _onUpdateNote(
    UpdateNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! NotesLoaded) {
        emit(const NotesLoading());
      }

      final response = await notesApi.updateNote(event.request);

      if (response.status == 'success') {
        // Reload notes to get the updated list
        add(const RefreshNotes());

        emit(NotesOperationSuccess(
          message: 'Note updated successfully',
          notes: currentState is NotesLoaded ? currentState.notes : [],
        ));
      } else {
        emit(NotesError(
          'Failed to update note',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(NotesError('Error updating note', details: e.toString()));
    }
  }

  Future<void> _onDeleteNote(
    DeleteNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      final currentState = state;

      final response = await notesApi.deleteNote(event.request);

      if (response.status == 'success') {
        // Remove note from current state
        if (currentState is NotesLoaded) {
          final updatedNotes = currentState.notes
              .where((note) => note.id != event.request.noteId)
              .toList();

          emit(currentState.copyWith(
            notes: updatedNotes,
            totalCount: currentState.totalCount - 1,
          ));
        } else {
          add(const RefreshNotes());
        }

        emit(NotesOperationSuccess(
          message: 'Note deleted successfully',
          notes: currentState is NotesLoaded ? currentState.notes : [],
        ));
      } else {
        emit(NotesError(
          'Failed to delete note',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(NotesError('Error deleting note', details: e.toString()));
    }
  }

  Future<void> _onSearchNotes(
    SearchNotes event,
    Emitter<NotesState> emit,
  ) async {
    try {
      emit(const NotesLoading());

      final response = await notesApi.searchNotes(event.request);

      if (response.status == 'success' && response.result != null) {
        final result = response.result!;
        final notesData = result['notes'] as List?;
        final notes = notesData
                ?.map((e) => Note.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        final query = result['query'] as String? ?? '';
        final count = result['count'] as int? ?? 0;

        emit(NotesSearchResults(
          notes: notes,
          query: query,
          count: count,
        ));
      } else {
        emit(NotesError(
          'Failed to search notes',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(NotesError('Error searching notes', details: e.toString()));
    }
  }

  Future<void> _onArchiveNote(
    ArchiveNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      final currentState = state;

      final response = await notesApi.archiveNote(event.request);

      if (response.status == 'success') {
        // Update note in current state or reload
        if (currentState is NotesLoaded) {
          final updatedNotes = currentState.notes
              .map((note) => note.id == event.request.noteId
                  ? note.copyWith(isArchived: event.request.isArchived)
                  : note)
              .toList();

          emit(currentState.copyWith(notes: updatedNotes));
        } else {
          add(const RefreshNotes());
        }
      } else {
        emit(NotesError(
          'Failed to archive note',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(NotesError('Error archiving note', details: e.toString()));
    }
  }

  Future<void> _onPinNote(
    PinNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      final currentState = state;

      final response = await notesApi.pinNote(event.request);

      if (response.status == 'success') {
        // Update note in current state or reload
        if (currentState is NotesLoaded) {
          final updatedNotes = currentState.notes
              .map((note) => note.id == event.request.noteId
                  ? note.copyWith(isPinned: event.request.isPinned)
                  : note)
              .toList();

          emit(currentState.copyWith(notes: updatedNotes));
        } else {
          add(const RefreshNotes());
        }
      } else {
        emit(NotesError(
          'Failed to pin note',
          details: response.message,
        ));
      }
    } catch (e) {
      emit(NotesError('Error pinning note', details: e.toString()));
    }
  }

  Future<void> _onRefreshNotes(
    RefreshNotes event,
    Emitter<NotesState> emit,
  ) async {
    // Reload with current filters
    add(const LoadNotes());
  }

  // WebSocket notification handlers
  void _onNoteAdded(
    NoteAdded event,
    Emitter<NotesState> emit,
  ) {
    final currentState = state;
    if (currentState is NotesLoaded) {
      final updatedNotes = [event.note, ...currentState.notes];
      emit(currentState.copyWith(
        notes: updatedNotes,
        totalCount: currentState.totalCount + 1,
      ));
    }
  }

  void _onNoteUpdated(
    NoteUpdated event,
    Emitter<NotesState> emit,
  ) {
    final currentState = state;
    if (currentState is NotesLoaded) {
      final updatedNotes = currentState.notes
          .map((note) => note.id == event.note.id ? event.note : note)
          .toList();
      emit(currentState.copyWith(notes: updatedNotes));
    }
  }

  void _onNoteDeleted(
    NoteDeleted event,
    Emitter<NotesState> emit,
  ) {
    final currentState = state;
    if (currentState is NotesLoaded) {
      final updatedNotes =
          currentState.notes.where((note) => note.id != event.noteId).toList();
      emit(currentState.copyWith(
        notes: updatedNotes,
        totalCount: currentState.totalCount - 1,
      ));
    }
  }

  void _onNoteArchived(
    NoteArchived event,
    Emitter<NotesState> emit,
  ) {
    final currentState = state;
    if (currentState is NotesLoaded) {
      final updatedNotes = currentState.notes
          .map((note) => note.id == event.noteId
              ? note.copyWith(isArchived: event.isArchived)
              : note)
          .toList();
      emit(currentState.copyWith(notes: updatedNotes));
    }
  }
}
