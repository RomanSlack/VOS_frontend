import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/models/notes_models.dart';
import 'package:vos_app/features/notes/bloc/notes_bloc.dart';
import 'package:vos_app/features/notes/bloc/notes_event.dart';
import 'package:vos_app/features/notes/bloc/notes_state.dart';
import 'package:vos_app/features/notes/widgets/note_card.dart';
import 'package:vos_app/features/notes/widgets/create_note_dialog.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showArchived = false;
  bool _showPinnedOnly = false;
  String? _selectedFolder;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    context.read<NotesBloc>().add(LoadNotes(
          isArchived: _showArchived,
          isPinned: _showPinnedOnly ? true : null,
          folder: _selectedFolder,
        ));
  }

  void _showCreateNoteDialog() {
    final bloc = context.read<NotesBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => CreateNoteDialog(
        onSave: (request) {
          bloc.add(CreateNote(request));
        },
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _loadNotes();
    } else {
      context.read<NotesBloc>().add(SearchNotes(
            SearchNotesRequest(
              query: query,
              createdBy: context.read<NotesBloc>().userId,
              folder: _selectedFolder,
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(_showPinnedOnly ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () {
              setState(() {
                _showPinnedOnly = !_showPinnedOnly;
              });
              _loadNotes();
            },
            tooltip: _showPinnedOnly ? 'Show All' : 'Show Pinned Only',
          ),
          IconButton(
            icon: Icon(_showArchived ? Icons.unarchive : Icons.archive_outlined),
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
              });
              _loadNotes();
            },
            tooltip: _showArchived ? 'Show Active' : 'Show Archived',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _performSearch,
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) {
                  _performSearch('');
                }
              },
            ),
          ),

          // Notes list
          Expanded(
            child: BlocConsumer<NotesBloc, NotesState>(
              listener: (context, state) {
                if (state is NotesOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (state is NotesError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is NotesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is NotesError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(state.message),
                        if (state.details != null) ...[
                          const SizedBox(height: 8),
                          Text(state.details!, style: Theme.of(context).textTheme.bodySmall),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNotes,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                List<Note> notes = [];
                int totalCount = 0;

                if (state is NotesLoaded) {
                  notes = state.notes;
                  totalCount = state.totalCount;
                } else if (state is NotesSearchResults) {
                  notes = state.notes;
                  totalCount = state.count;
                } else if (state is NotesOperationSuccess) {
                  notes = state.notes;
                }

                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showArchived ? Icons.archive_outlined : Icons.note_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showArchived
                              ? 'No archived notes'
                              : _searchController.text.isNotEmpty
                                  ? 'No notes found'
                                  : 'No notes yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showArchived
                              ? 'Archive notes to see them here'
                              : _searchController.text.isNotEmpty
                                  ? 'Try a different search'
                                  : 'Tap + to create your first note',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadNotes();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == notes.length) {
                        // Footer with count
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Showing ${notes.length} of $totalCount notes',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                        );
                      }

                      final note = notes[index];
                      return NoteCard(
                        note: note,
                        onTap: () {
                          // Navigate to detail page or edit
                          _showEditNoteDialog(note);
                        },
                        onPin: () {
                          context.read<NotesBloc>().add(PinNote(
                                PinNoteRequest(
                                  noteId: note.id,
                                  isPinned: !note.isPinned,
                                  createdBy: context.read<NotesBloc>().userId,
                                ),
                              ));
                        },
                        onArchive: () {
                          context.read<NotesBloc>().add(ArchiveNote(
                                ArchiveNoteRequest(
                                  noteId: note.id,
                                  isArchived: !note.isArchived,
                                  createdBy: context.read<NotesBloc>().userId,
                                ),
                              ));
                        },
                        onDelete: () {
                          _confirmDelete(note);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditNoteDialog(Note note) {
    final bloc = context.read<NotesBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => CreateNoteDialog(
        existingNote: note,
        onSave: (request) {
          bloc.add(UpdateNote(
                UpdateNoteRequest(
                  noteId: note.id,
                  title: request.title,
                  content: request.content,
                  tags: request.tags,
                  folder: request.folder,
                  color: request.color,
                  isPinned: request.isPinned,
                  createdBy: request.createdBy,
                ),
              ));
        },
      ),
    );
  }

  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              this.context.read<NotesBloc>().add(DeleteNote(
                    DeleteNoteRequest(
                      noteId: note.id,
                      createdBy: this.context.read<NotesBloc>().userId,
                    ),
                  ));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
