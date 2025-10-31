import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/notes_models.dart';

abstract class NotesBlocEvent extends Equatable {
  const NotesBlocEvent();

  @override
  List<Object?> get props => [];
}

// Load notes list
class LoadNotes extends NotesBlocEvent {
  final String? folder;
  final List<String>? tags;
  final bool? isPinned;
  final bool? isArchived;
  final int? limit;
  final int? offset;
  final String? sortBy;
  final String? sortOrder;

  const LoadNotes({
    this.folder,
    this.tags,
    this.isPinned,
    this.isArchived,
    this.limit,
    this.offset,
    this.sortBy,
    this.sortOrder,
  });

  @override
  List<Object?> get props => [folder, tags, isPinned, isArchived, limit, offset, sortBy, sortOrder];
}

// Load a single note
class LoadNote extends NotesBlocEvent {
  final int noteId;

  const LoadNote(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

// Create new note
class CreateNote extends NotesBlocEvent {
  final CreateNoteRequest request;

  const CreateNote(this.request);

  @override
  List<Object?> get props => [request];
}

// Update existing note
class UpdateNote extends NotesBlocEvent {
  final UpdateNoteRequest request;

  const UpdateNote(this.request);

  @override
  List<Object?> get props => [request];
}

// Delete note
class DeleteNote extends NotesBlocEvent {
  final DeleteNoteRequest request;

  const DeleteNote(this.request);

  @override
  List<Object?> get props => [request];
}

// Search notes
class SearchNotes extends NotesBlocEvent {
  final SearchNotesRequest request;

  const SearchNotes(this.request);

  @override
  List<Object?> get props => [request];
}

// Archive/unarchive note
class ArchiveNote extends NotesBlocEvent {
  final ArchiveNoteRequest request;

  const ArchiveNote(this.request);

  @override
  List<Object?> get props => [request];
}

// Pin/unpin note
class PinNote extends NotesBlocEvent {
  final PinNoteRequest request;

  const PinNote(this.request);

  @override
  List<Object?> get props => [request];
}

// Refresh notes list
class RefreshNotes extends NotesBlocEvent {
  const RefreshNotes();
}

// Events from app interactions (WebSocket notifications)
class NoteAdded extends NotesBlocEvent {
  final Note note;

  const NoteAdded(this.note);

  @override
  List<Object?> get props => [note];
}

class NoteUpdated extends NotesBlocEvent {
  final Note note;

  const NoteUpdated(this.note);

  @override
  List<Object?> get props => [note];
}

class NoteDeleted extends NotesBlocEvent {
  final int noteId;

  const NoteDeleted(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

class NoteArchived extends NotesBlocEvent {
  final int noteId;
  final bool isArchived;

  const NoteArchived(this.noteId, this.isArchived);

  @override
  List<Object?> get props => [noteId, isArchived];
}
