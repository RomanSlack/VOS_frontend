import 'package:flutter/material.dart';
import 'package:vos_app/core/models/notes_models.dart';

class StickyNoteInstance {
  final String id;
  final Note note;
  Offset position;

  StickyNoteInstance({
    required this.id,
    required this.note,
    required this.position,
  });
}

class StickyNotesManager extends ChangeNotifier {
  final Map<String, StickyNoteInstance> _stickyNotes = {};

  List<StickyNoteInstance> get stickyNotes => _stickyNotes.values.toList();

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
