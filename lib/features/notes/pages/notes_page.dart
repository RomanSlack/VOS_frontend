import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/models/notes_models.dart';
import 'package:vos_app/features/notes/bloc/notes_bloc.dart';
import 'package:vos_app/features/notes/bloc/notes_event.dart';
import 'package:vos_app/features/notes/bloc/notes_state.dart';
import 'package:vos_app/features/notes/widgets/note_card.dart';
import 'package:vos_app/features/notes/widgets/create_note_dialog.dart';
import 'package:vos_app/features/notes/widgets/note_fullscreen_view.dart';

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
  Note? _selectedNote; // Track selected note for fullscreen view
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    // Auto-sync every second
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_selectedNote == null && _searchController.text.isEmpty) {
        _loadNotes();
      }
    });
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
    // If a note is selected, show fullscreen view
    if (_selectedNote != null) {
      return _buildFullscreenView();
    }

    return Scaffold(
      appBar: AppBar(
        title: null, // No title for cleaner look
        toolbarHeight: 48, // Smaller toolbar
        actions: [
          // Compact filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: _showPinnedOnly ? Colors.amber : null,
                      ),
                      const SizedBox(width: 4),
                      Text(_showPinnedOnly ? 'Starred' : 'All'),
                    ],
                  ),
                  selected: _showPinnedOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showPinnedOnly = selected;
                    });
                    _loadNotes();
                  },
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showArchived ? Icons.unarchive : Icons.archive_outlined,
                        size: 16,
                        color: _showArchived ? Colors.white : null,
                      ),
                      const SizedBox(width: 4),
                      Text(_showArchived ? 'Archived' : 'Active'),
                    ],
                  ),
                  selected: _showArchived,
                  onSelected: (selected) {
                    setState(() {
                      _showArchived = selected;
                    });
                    _loadNotes();
                  },
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar - more compact
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                isDense: true,
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate number of columns based on screen width
                      int crossAxisCount;
                      double cardWidth;

                      if (constraints.maxWidth < 600) {
                        crossAxisCount = 1; // Mobile: 1 column
                        cardWidth = constraints.maxWidth - 32;
                      } else if (constraints.maxWidth < 900) {
                        crossAxisCount = 2; // Tablet: 2 columns
                        cardWidth = (constraints.maxWidth - 44) / 2;
                      } else if (constraints.maxWidth < 1200) {
                        crossAxisCount = 3; // Small desktop: 3 columns
                        cardWidth = (constraints.maxWidth - 56) / 3;
                      } else if (constraints.maxWidth < 1600) {
                        crossAxisCount = 4; // Medium desktop: 4 columns
                        cardWidth = (constraints.maxWidth - 68) / 4;
                      } else {
                        crossAxisCount = 5; // Large desktop: 5 columns
                        cardWidth = (constraints.maxWidth - 80) / 5;
                      }

                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(12),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, outerIndex) {
                                  // Calculate which row this is
                                  final rowStartIndex = outerIndex * crossAxisCount;
                                  if (rowStartIndex >= notes.length) return null;

                                  // Build a row with the appropriate number of cards
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: List.generate(crossAxisCount, (colIndex) {
                                        final noteIndex = rowStartIndex + colIndex;
                                        if (noteIndex >= notes.length) {
                                          return Expanded(child: Container());
                                        }

                                        final note = notes[noteIndex];
                                        return Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              right: colIndex < crossAxisCount - 1 ? 12 : 0,
                                            ),
                                            child: NoteCard(
                                              note: note,
                                              onTap: () {
                                                // Show fullscreen view
                                                setState(() {
                                                  _selectedNote = note;
                                                });
                                              },
                                              onStar: () {
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
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  );
                                },
                                childCount: (notes.length / crossAxisCount).ceil(),
                              ),
                            ),
                          ),
                          // Footer with count
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'Showing ${notes.length} of $totalCount notes',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildFullscreenView() {
    if (_selectedNote == null) return const SizedBox();

    final bloc = context.read<NotesBloc>();
    return NoteFullscreenView(
      note: _selectedNote!,
      onBack: () {
        setState(() {
          _selectedNote = null;
        });
        _loadNotes(); // Reload to get any updates
      },
      onStar: () {
        bloc.add(PinNote(
              PinNoteRequest(
                noteId: _selectedNote!.id,
                isPinned: !_selectedNote!.isPinned,
                createdBy: bloc.userId,
              ),
            ));
        // Update local state
        setState(() {
          _selectedNote = _selectedNote!.copyWith(isPinned: !_selectedNote!.isPinned);
        });
      },
      onArchive: () {
        bloc.add(ArchiveNote(
              ArchiveNoteRequest(
                noteId: _selectedNote!.id,
                isArchived: !_selectedNote!.isArchived,
                createdBy: bloc.userId,
              ),
            ));
        setState(() {
          _selectedNote = null;
        });
      },
      onDelete: () {
        _confirmDelete(_selectedNote!);
        setState(() {
          _selectedNote = null;
        });
      },
      onUpdate: (request) {
        bloc.add(UpdateNote(request));
      },
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
    _autoSyncTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
