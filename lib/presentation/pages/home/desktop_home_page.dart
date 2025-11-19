import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/app_rail.dart';
import 'package:vos_app/presentation/widgets/input_bar.dart';
import 'package:vos_app/presentation/widgets/workspace.dart';
import 'package:vos_app/presentation/widgets/modal_limit_notification.dart';
import 'package:vos_app/presentation/widgets/zoom_controls.dart';
import 'package:vos_app/presentation/widgets/sticky_note.dart';
import 'package:vos_app/core/modal_manager.dart';
import 'package:vos_app/core/sticky_notes_manager.dart';
import 'package:vos_app/core/models/notes_models.dart';

/// Desktop VOS layout with:
/// - AppRail on the left
/// - Floating modals with drag/resize
/// - Zoom controls
/// - Full modal management
class DesktopHomePage extends StatelessWidget {
  final VosModalManager modalManager;
  final StickyNotesManager stickyNotesManager;

  const DesktopHomePage({
    super.key,
    required this.modalManager,
    required this.stickyNotesManager,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Zoomable workspace area (everything except AppRail, InputBar, and ZoomControls)
          _ZoomableWorkspace(
            modalManager: modalManager,
            stickyNotesManager: stickyNotesManager,
          ),
          // Fixed UI elements (not affected by zoom)
          Row(
            children: [
              AppRail(modalManager: modalManager),
              const Expanded(
                child: SizedBox(), // Empty space for now
              ),
            ],
          ),
          // Modal limit notification
          ModalLimitNotification(modalManager: modalManager),
          Align(
            alignment: Alignment.bottomCenter,
            child: InputBar(modalManager: modalManager),
          ),
          // Zoom controls in bottom right
          ZoomControls(modalManager: modalManager),
        ],
      ),
    );
  }
}

// Zoomable workspace widget that applies zoom transform
class _ZoomableWorkspace extends StatelessWidget {
  final VosModalManager modalManager;
  final StickyNotesManager stickyNotesManager;

  const _ZoomableWorkspace({
    required this.modalManager,
    required this.stickyNotesManager,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: modalManager.zoomLevelNotifier,
      builder: (context, zoomLevel, child) {
        return Transform.scale(
          scale: zoomLevel,
          alignment: Alignment.center,
          child: Stack(
            children: [
              const Workspace(), // Grid background behind everything
              // DragTarget for sticky notes
              DragTarget<Note>(
                onWillAccept: (note) => note != null,
                onAcceptWithDetails: (details) {
                  // Calculate position relative to screen, accounting for zoom
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset localPosition = box.globalToLocal(details.offset);
                  // Adjust position for zoom level
                  final adjustedPosition = Offset(
                    localPosition.dx / zoomLevel,
                    localPosition.dy / zoomLevel,
                  );
                  stickyNotesManager.addStickyNote(details.data, adjustedPosition);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    color: candidateData.isNotEmpty
                        ? Colors.green.withOpacity(0.1)
                        : Colors.transparent,
                  );
                },
              ),
              // Optimized modal rendering
              _OptimizedModalStack(modalManager: modalManager),
              // Sticky notes overlay
              _StickyNotesOverlay(stickyNotesManager: stickyNotesManager),
            ],
          ),
        );
      },
    );
  }
}

// Separate widget to isolate modal rebuilds
class _OptimizedModalStack extends StatelessWidget {
  final VosModalManager modalManager;

  const _OptimizedModalStack({
    required this.modalManager,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: modalManager,
      builder: (context, child) {
        final openModals = modalManager.openModals;
        final minimizedModals = modalManager.minimizedModals;

        // Combine all modals into one list to maintain consistent keys
        final allModals = [...openModals, ...minimizedModals];

        // Render all modals with consistent keys
        // Modals handle their own visibility based on state
        return Stack(
          children: allModals.map((modalInstance) {
            return KeyedSubtree(
              key: ValueKey(modalInstance.appId),
              child: modalInstance.modal,
            );
          }).toList(),
        );
      },
    );
  }
}

// Sticky notes overlay widget
class _StickyNotesOverlay extends StatelessWidget {
  final StickyNotesManager stickyNotesManager;

  const _StickyNotesOverlay({
    required this.stickyNotesManager,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: stickyNotesManager,
      builder: (context, child) {
        return Stack(
          children: stickyNotesManager.stickyNotes.map((stickyNote) {
            return StickyNote(
              key: ValueKey(stickyNote.id),
              note: stickyNote.note,
              position: stickyNote.position,
              onDelete: () {
                stickyNotesManager.removeStickyNote(stickyNote.id);
              },
              onPositionChanged: (newPosition) {
                stickyNotesManager.updateStickyNotePosition(stickyNote.id, newPosition);
              },
            );
          }).toList(),
        );
      },
    );
  }
}
