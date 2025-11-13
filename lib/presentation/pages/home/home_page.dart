import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/app_rail.dart';
import 'package:vos_app/presentation/widgets/input_bar.dart';
import 'package:vos_app/presentation/widgets/workspace.dart';
import 'package:vos_app/presentation/widgets/modal_limit_notification.dart';
import 'package:vos_app/presentation/widgets/vos_modal.dart';
import 'package:vos_app/presentation/widgets/notification_toast.dart';
import 'package:vos_app/presentation/widgets/sticky_note.dart';
import 'package:vos_app/presentation/widgets/zoom_controls.dart';
import 'package:vos_app/core/modal_manager.dart';
import 'package:vos_app/core/sticky_notes_manager.dart';
import 'package:vos_app/core/services/calendar_service.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/core/utils/logger.dart';
import 'package:vos_app/core/models/notes_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  VosModalManager? _modalManager;
  final StickyNotesManager _stickyNotesManager = StickyNotesManager();

  @override
  void initState() {
    super.initState();
    // Delay initialization to ensure GetIt is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _modalManager = VosModalManager();
      });
      _initializeNotifications();
    });
  }

  void _initializeNotifications() {
    final calendarService = getIt<CalendarService>();
    final notificationService = calendarService.notificationService;

    // Setup callback for reminder notifications
    notificationService.onReminderTriggered = (reminder) {
      logger.i('HomePage: Reminder triggered: ${reminder.title}');
      if (mounted) {
        NotificationToastManager.show(context, reminder);
      }
    };

    // Connect to WebSocket
    notificationService.connect().then((_) {
      logger.i('HomePage: Calendar notification service connected');
    }).catchError((error) {
      logger.e('HomePage: Failed to connect notification service: $error');
    });
  }

  @override
  void dispose() {
    _modalManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while modal manager is initializing
    if (_modalManager == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF212121),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00BCD4),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Zoomable workspace area (everything except AppRail, InputBar, and ZoomControls)
          _ZoomableWorkspace(
            modalManager: _modalManager!,
            stickyNotesManager: _stickyNotesManager,
          ),
          // Fixed UI elements (not affected by zoom)
          Row(
            children: [
              AppRail(modalManager: _modalManager!),
              const Expanded(
                child: SizedBox(), // Empty space for now
              ),
            ],
          ),
          // Modal limit notification
          ModalLimitNotification(modalManager: _modalManager!),
          Align(
            alignment: Alignment.bottomCenter,
            child: InputBar(modalManager: _modalManager!),
          ),
          // Zoom controls in bottom right
          ZoomControls(modalManager: _modalManager!),
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