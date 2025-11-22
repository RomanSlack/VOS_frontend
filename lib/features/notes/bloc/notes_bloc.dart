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
      // Don't show loading if we already have data (prevents flashing)
      final shouldShowLoading = state is! NotesLoaded;
      if (shouldShowLoading) {
        emit(const NotesLoading());
      }

      final response = await notesApi.listNotes(
        folder: event.folder,
        tags: event.tags,
        isPinned: event.isPinned,
        isArchived: event.isArchived ?? false,
        // createdBy omitted to get all notes
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

        // Only emit if data has actually changed
        if (state is NotesLoaded) {
          final currentState = state as NotesLoaded;
          final hasChanged = currentState.notes.length != notes.length ||
              currentState.totalCount != totalCount ||
              !_areNotesEqual(currentState.notes, notes);

          if (!hasChanged) {
            return; // No change, don't emit
          }
        }

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

  bool _areNotesEqual(List<Note> list1, List<Note> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].updatedAt != list2[i].updatedAt) {
        return false;
      }
    }
    return true;
  }

  Future<void> _onLoadNote(
    LoadNote event,
    Emitter<NotesState> emit,
  ) async {
    try {
      emit(const NotesLoading());

      final response = await notesApi.getNote(
        noteId: event.noteId,
        // createdBy omitted to get any note
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
      final response = await notesApi.createNote(event.request);

      if (response.status == 'success' && response.result != null) {
        // Immediately reload notes to show the new note
        final listResponse = await notesApi.listNotes(
          isArchived: false,
          // createdBy omitted to get all notes
          limit: 50,
          offset: 0,
          sortBy: 'updated_at',
          sortOrder: 'desc',
        );

        if (listResponse.status == 'success' && listResponse.result != null) {
          final result = listResponse.result!;
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

          // Show success message
          emit(NotesOperationSuccess(
            message: 'Note created successfully',
            notes: notes,
          ));
        }
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
