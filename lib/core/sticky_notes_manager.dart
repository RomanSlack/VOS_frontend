import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vos_app/core/models/notes_models.dart';
import 'package:vos_app/core/models/chat_models.dart';
import 'package:vos_app/core/services/chat_service.dart';

class StickyNoteInstance {
  final String id;
  Note note;
  Offset position;

  StickyNoteInstance({
    required this.id,
    required this.note,
    required this.position,
  });
}

class StickyNotesManager extends ChangeNotifier {
  final Map<String, StickyNoteInstance> _stickyNotes = {};
  StreamSubscription<AppInteractionPayload>? _appInteractionSubscription;

  List<StickyNoteInstance> get stickyNotes => _stickyNotes.values.toList();

  void subscribeToWebSocket(ChatService chatService) {
    _appInteractionSubscription?.cancel();
    _appInteractionSubscription = chatService.appInteractionStream.listen(
      (payload) {
        if (payload.appName == 'notes') {
          switch (payload.action) {
            case 'note_viewed':
              // Full content received from get_note
              try {
                final noteWithContent = Note.fromJson(payload.result);
                updateNoteContent(noteWithContent);
                debugPrint('📝 Sticky note updated with full content: ${noteWithContent.title}');
              } catch (e) {
                debugPrint('Error updating sticky note with content: $e');
              }
              break;
            case 'note_updated':
              try {
                final updatedNote = Note.fromJson(payload.result);
                updateNoteContent(updatedNote);
              } catch (e) {
                debugPrint('Error updating sticky note: $e');
              }
              break;
            case 'note_deleted':
              try {
                final noteId = payload.result['id'] as int;
                removeByNoteId(noteId);
              } catch (e) {
                debugPrint('Error removing sticky note: $e');
              }
              break;
          }
        }
      },
      onError: (error) {
        debugPrint('Error in sticky notes app interaction stream: $error');
      },
    );
  }

  void updateNoteContent(Note updatedNote) {
    bool changed = false;
    for (final instance in _stickyNotes.values) {
      if (instance.note.id == updatedNote.id) {
        instance.note = updatedNote;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void removeByNoteId(int noteId) {
    final keysToRemove = _stickyNotes.entries
        .where((entry) => entry.value.note.id == noteId)
        .map((entry) => entry.key)
        .toList();

    if (keysToRemove.isNotEmpty) {
      for (final key in keysToRemove) {
        _stickyNotes.remove(key);
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _appInteractionSubscription?.cancel();
    super.dispose();
  }

  void addStickyNote(Note note, Offset position) {
    final id = 'sticky_${note.id}_${DateTime.now().millisecondsSinceEpoch}';
    _stickyNotes[id] = StickyNoteInstance(
      id: id,
      note: note,
      position: position,
    );
    notifyListeners();
  }

  void removeStickyNote(String id) {
    _stickyNotes.remove(id);
    notifyListeners();
  }

  void updateStickyNotePosition(String id, Offset position) {
    final stickyNote = _stickyNotes[id];
    if (stickyNote != null) {
      stickyNote.position = position;
      notifyListeners();
    }
  }

  bool hasStickyNote(int noteId) {
    return _stickyNotes.values.any((sticky) => sticky.note.id == noteId);
  }
}
