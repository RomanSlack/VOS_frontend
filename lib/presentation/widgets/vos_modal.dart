import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/circle_icon.dart';
import 'package:vos_app/presentation/widgets/wave_text_animation.dart';

enum ModalState { normal, minimized, fullscreen }

class VosModal extends StatefulWidget {
  final IconData appIcon;
  final String title;
  final Widget child;
  final double initialWidth;
  final double initialHeight;
  final Offset initialPosition;
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final VoidCallback? onFullscreen;
  final VoidCallback? onInteraction;
  final ValueNotifier<String?>? statusNotifier;
  final ValueNotifier<bool>? isActiveNotifier;
  final ValueNotifier<ModalState>? stateNotifier;
  final ValueNotifier<double>? zoomLevelNotifier;

  const VosModal({
    super.key,
    required this.appIcon,
    required this.title,
    required this.child,
    this.initialWidth = 400,
    this.initialHeight = 300,
    this.initialPosition = const Offset(150, 100),
    this.onClose,
    this.onMinimize,
    this.onFullscreen,
    this.onInteraction,
    this.statusNotifier,
    this.isActiveNotifier,
    this.stateNotifier,
    this.zoomLevelNotifier,
  });

  @override
  State<VosModal> createState() => _VosModalState();
}

class _VosModalState extends State<VosModal> {
  late double _width;
  late double _height;
  late Offset _position;
  ModalState _state = ModalState.normal;

  // Use ValueNotifiers for drag/resize to avoid rebuilding entire modal
  late final ValueNotifier<Offset> _positionNotifier;
  late final ValueNotifier<Size> _sizeNotifier;

  // For dragging
  Offset _dragStartPosition = Offset.zero;
  Offset _dragStartOffset = Offset.zero;
  bool _isDragging = false;

  // For resizing
  bool _isResizing = false;
  Offset _resizeStartPosition = Offset.zero;
  double _resizeStartWidth = 0;
  double _resizeStartHeight = 0;

  // Constants from VOS design system
  static const double _titleBarHeight = 40;
  static const double _iconSize = 24;
  static const double _iconSpacing = 8;
  static const double _borderRadius = 16;
  static const double _minWidth = 200;
  static const double _minHeight = 150;
  static const Color _surfaceColor = Color(0xFF303030);
  static const Color _textColor = Color(0xFFEDEDED);

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
    _height = widget.initialHeight;
    _position = widget.initialPosition;
    _positionNotifier = ValueNotifier(_position);
    _sizeNotifier = ValueNotifier(Size(_width, _height));
  }

  @override
  void dispose() {
    _positionNotifier.dispose();
    _sizeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If we have a state notifier, use ValueListenableBuilder to rebuild on changes
    if (widget.stateNotifier != null) {
      return ValueListenableBuilder<ModalState>(
        valueListenable: widget.stateNotifier!,
        builder: (context, externalState, child) {
          return _buildModal(context, externalState);
        },
      );
    }
    return _buildModal(context, _state);
  }

  Widget _buildModal(BuildContext context, ModalState currentState) {
    final isMinimized = currentState == ModalState.minimized;

    // Use ValueListenableBuilder to only rebuild position/size on drag/resize
    return ValueListenableBuilder<Offset>(
      valueListenable: _positionNotifier,
      builder: (context, position, child) {
        // When fullscreen, position at top-left of available space (accounting for app rail)
        final left = currentState == ModalState.fullscreen ? 112.0 : position.dx;
        final top = currentState == ModalState.fullscreen ? 16.0 : position.dy;

        return Positioned(
          left: left,
          top: top,
          child: child!,
        );
      },
      child: IgnorePointer(
        ignoring: isMinimized,
        child: Opacity(
          opacity: isMinimized ? 0.0 : 1.0,
          child: ValueListenableBuilder<Size>(
            valueListenable: _sizeNotifier,
            builder: (context, size, child) {
              return Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () => widget.onInteraction?.call(),
                  child: Container(
                    width: currentState == ModalState.fullscreen ? MediaQuery.of(context).size.width - 144 : size.width,
                    height: currentState == ModalState.fullscreen ? MediaQuery.of(context).size.height - 148 : size.height,
                    decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(_borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Wrap content in RepaintBoundary to isolate child repaints from resize handle
              child!,
              if (currentState != ModalState.fullscreen) _buildResizeHandle(),
            ],
                    ),
                  ),
                ),
              );
            },
            // Static child to avoid rebuilding on size changes
            child: Column(
              children: [
                _buildTitleBar(currentState),
                Expanded(
                  child: RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(_borderRadius),
                        bottomRight: Radius.circular(_borderRadius),
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(ModalState currentState) {
    return GestureDetector(
      // Disable dragging when fullscreen
      onPanStart: currentState != ModalState.fullscreen ? _onDragStart : null,
      onPanUpdate: currentState != ModalState.fullscreen ? _onDragUpdate : null,
      onPanEnd: currentState != ModalState.fullscreen ? _onDragEnd : null,
      child: Container(
        height: _titleBarHeight,
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_borderRadius),
            topRight: Radius.circular(_borderRadius),
          ),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Left side: Icon and Status
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with hover-to-show-title animation
                  _AnimatedTitleIcon(
                    icon: widget.appIcon,
                    title: widget.title,
                  ),
                  // Status indicator (if available)
                  if (widget.statusNotifier != null)
                    ValueListenableBuilder<String?>(
                      valueListenable: widget.statusNotifier!,
                      builder: (context, status, child) {
                        if (status == null || status.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 12),
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.3,
                              ),
                              child: WaveTextAnimation(
                                text: status,
                                isActiveNotifier: widget.isActiveNotifier,
                                style: const TextStyle(
                                  color: Color(0xFF00BCD4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            // Right side: Window controls
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: _buildWindowControls(currentState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowControls(ModalState currentState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleIcon(
          icon: Icons.minimize,
          size: _iconSize,
          useFontAwesome: false,
          backgroundColor: const Color(0xFF424242),
          onPressed: _onMinimizePressed,
        ),
        const SizedBox(width: _iconSpacing),
        CircleIcon(
          key: ValueKey(currentState), // Only rebuild when state changes
          icon: currentState == ModalState.fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          size: _iconSize,
          useFontAwesome: false,
          backgroundColor: const Color(0xFF424242),
          onPressed: _onFullscreenPressed,
        ),
        const SizedBox(width: _iconSpacing),
        CircleIcon(
          icon: Icons.close,
          size: _iconSize,
          useFontAwesome: false,
          backgroundColor: const Color(0xFF424242),
          onPressed: _onClosePressed,
        ),
      ],
    );
  }

  void _onDragStart(DragStartDetails details) {
    final currentState = widget.stateNotifier?.value ?? _state;
    if (currentState == ModalState.fullscreen) return;

    widget.onInteraction?.call();
    _isDragging = true;
    _dragStartPosition = details.globalPosition;
    _dragStartOffset = _position;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final currentState = widget.stateNotifier?.value ?? _state;
    if (!_isDragging || currentState == ModalState.fullscreen) return;

    // Get current zoom level (default to 1.0 if not provided)
    final zoomLevel = widget.zoomLevelNotifier?.value ?? 1.0;

    // Use ValueNotifier instead of setState for smooth drag without rebuilding children
    // Convert screen-space delta to workspace-space delta by dividing by zoom
    final delta = (details.globalPosition - _dragStartPosition) / zoomLevel;
    _position = _dragStartOffset + delta;

    // Keep modal within workspace bounds (convert screen bounds to workspace bounds)
    final screenSize = MediaQuery.of(context).size;
    final workspaceLeft = 112.0 / zoomLevel; // AppRail width + margins
    final workspaceRight = (screenSize.width - 16.0) / zoomLevel;
    final workspaceTop = 0.0;
    final workspaceBottom = (screenSize.height - 100.0) / zoomLevel; // Above input bar

    _position = Offset(
      _position.dx.clamp(workspaceLeft, workspaceRight - _width),
      _position.dy.clamp(workspaceTop, workspaceBottom - _height),
    );

    // Update notifier to trigger only position rebuild
    _positionNotifier.value = _position;
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
  }

  void _onMinimizePressed() {
    setState(() {
      _state = _state == ModalState.minimized ? ModalState.normal : ModalState.minimized;
    });
    widget.onMinimize?.call();
  }

  void _onFullscreenPressed() {
    // If we have external state control, let the callback handle it
    if (widget.stateNotifier != null) {
      // Position update still needs to happen locally
      if (widget.stateNotifier!.value != ModalState.fullscreen) {
        setState(() {
          // Center the modal when going fullscreen
          final screenSize = MediaQuery.of(context).size;
          _position = Offset(112, 24); // Workspace padding
        });
      }
      // Callback will update the external state
      widget.onFullscreen?.call();
    } else {
      // Fallback to internal state management
      setState(() {
        if (_state == ModalState.fullscreen) {
          _state = ModalState.normal;
        } else {
          _state = ModalState.fullscreen;
          // Center the modal when going fullscreen
          final screenSize = MediaQuery.of(context).size;
          _position = Offset(112, 24); // Workspace padding
        }
      });
      widget.onFullscreen?.call();
    }
  }

  void _onClosePressed() {
    widget.onClose?.call();
  }

  Widget _buildResizeHandle() {
    return Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onPanStart: _onResizeStart,
        onPanUpdate: _onResizeUpdate,
        onPanEnd: _onResizeEnd,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeDownRight,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(_borderRadius),
              ),
            ),
            child: CustomPaint(
              painter: ResizeHandlePainter(),
            ),
          ),
        ),
      ),
    );
  }

  void _onResizeStart(DragStartDetails details) {
    widget.onInteraction?.call();
    _isResizing = true;
    _resizeStartPosition = details.globalPosition;
    _resizeStartWidth = _width;
    _resizeStartHeight = _height;
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    if (!_isResizing) return;

    // Get current zoom level (default to 1.0 if not provided)
    final zoomLevel = widget.zoomLevelNotifier?.value ?? 1.0;

    // Use ValueNotifier instead of setState for smooth resize without rebuilding children
    // Convert screen-space delta to workspace-space delta by dividing by zoom
    final delta = (details.globalPosition - _resizeStartPosition) / zoomLevel;
    _width = (_resizeStartWidth + delta.dx).clamp(_minWidth, double.infinity);
    _height = (_resizeStartHeight + delta.dy).clamp(_minHeight, double.infinity);

    // Ensure modal doesn't go beyond workspace bounds (convert screen bounds to workspace bounds)
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = (screenSize.width - 16.0) / zoomLevel - _position.dx;
    final maxHeight = (screenSize.height - 100.0) / zoomLevel - _position.dy;

    _width = _width.clamp(_minWidth, maxWidth);
    _height = _height.clamp(_minHeight, maxHeight);

    // Update notifier to trigger only size rebuild
    _sizeNotifier.value = Size(_width, _height);
  }

  void _onResizeEnd(DragEndDetails details) {
    _isResizing = false;
  }
}

// Custom painter for resize handle
class ResizeHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF757575)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Draw resize lines
    for (int i = 0; i < 3; i++) {
      final offset = i * 4.0 + 6.0;
      canvas.drawLine(
        Offset(size.width - offset, size.height - 4),
        Offset(size.width - 4, size.height - offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated icon that expands to show title on hover
class _AnimatedTitleIcon extends StatefulWidget {
  final IconData icon;
  final String title;

  const _AnimatedTitleIcon({
    required this.icon,
    required this.title,
  });

  @override
  State<_AnimatedTitleIcon> createState() => _AnimatedTitleIconState();
}

class _AnimatedTitleIconState extends State<_AnimatedTitleIcon>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Scale animation for the "pop" effect
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Slide animation for the text appearance
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates animation from parent
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) {
          if (!_isHovered) {
            setState(() => _isHovered = true);
            _controller.forward();
          }
        },
        onExit: (_) {
          if (_isHovered) {
            setState(() => _isHovered = false);
            _controller.reverse();
          }
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          // Static child to avoid rebuilding icon/text
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon (always visible)
              Icon(
                widget.icon,
                size: 20,
                color: const Color(0xFFEDEDED),
              ),
              // Title (slides in on hover)
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _slideAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension for easier modal management
class ModalManager extends ChangeNotifier {
  final List<VosModal> _modals = [];
  final Map<String, ModalState> _modalStates = {};

  List<VosModal> get modals => List.unmodifiable(_modals);

  void addModal(String id, VosModal modal) {
    _modals.add(modal);
    _modalStates[id] = ModalState.normal;
    notifyListeners();
  }

  void removeModal(String id) {
    _modals.removeWhere((modal) => modal.title == id);
    _modalStates.remove(id);
    notifyListeners();
  }

  void minimizeModal(String id) {
    _modalStates[id] = ModalState.minimized;
    notifyListeners();
  }

  void restoreModal(String id) {
    _modalStates[id] = ModalState.normal;
    notifyListeners();
  }

  bool isMinimized(String id) {
    return _modalStates[id] == ModalState.minimized;
  }
}