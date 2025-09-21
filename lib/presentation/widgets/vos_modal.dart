import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/circle_icon.dart';

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
  });

  @override
  State<VosModal> createState() => _VosModalState();
}

class _VosModalState extends State<VosModal> {
  late double _width;
  late double _height;
  late Offset _position;
  ModalState _state = ModalState.normal;

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
  }

  @override
  Widget build(BuildContext context) {
    if (_state == ModalState.minimized) {
      return const SizedBox.shrink(); // Hidden when minimized
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _state == ModalState.fullscreen ? MediaQuery.of(context).size.width - 144 : _width,
          height: _state == ModalState.fullscreen ? MediaQuery.of(context).size.height - 48 : _height,
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
              Column(
                children: [
                  _buildTitleBar(),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(_borderRadius),
                        bottomRight: Radius.circular(_borderRadius),
                      ),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
              if (_state != ModalState.fullscreen) _buildResizeHandle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
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
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              widget.title,
              style: const TextStyle(
                color: _textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            _buildWindowControls(),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowControls() {
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
          key: ValueKey(_state), // Only rebuild when state changes
          icon: _state == ModalState.fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
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
        const SizedBox(width: _iconSpacing),
        CircleIcon(
          icon: widget.appIcon,
          size: _iconSize,
          useFontAwesome: false,
          backgroundColor: const Color(0xFF424242),
          onPressed: null, // App icon is not clickable
        ),
      ],
    );
  }

  void _onDragStart(DragStartDetails details) {
    if (_state == ModalState.fullscreen) return;

    _isDragging = true;
    _dragStartPosition = details.globalPosition;
    _dragStartOffset = _position;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _state == ModalState.fullscreen) return;

    setState(() {
      final delta = details.globalPosition - _dragStartPosition;
      _position = _dragStartOffset + delta;

      // Keep modal within workspace bounds
      final screenSize = MediaQuery.of(context).size;
      final workspaceLeft = 112.0; // AppRail width + margins
      final workspaceRight = screenSize.width - 16.0;
      final workspaceTop = 0.0;
      final workspaceBottom = screenSize.height - 100.0; // Above input bar

      _position = Offset(
        _position.dx.clamp(workspaceLeft, workspaceRight - _width),
        _position.dy.clamp(workspaceTop, workspaceBottom - _height),
      );
    });
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
    _isResizing = true;
    _resizeStartPosition = details.globalPosition;
    _resizeStartWidth = _width;
    _resizeStartHeight = _height;
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    if (!_isResizing) return;

    setState(() {
      final delta = details.globalPosition - _resizeStartPosition;
      _width = (_resizeStartWidth + delta.dx).clamp(_minWidth, double.infinity);
      _height = (_resizeStartHeight + delta.dy).clamp(_minHeight, double.infinity);

      // Ensure modal doesn't go beyond workspace bounds
      final screenSize = MediaQuery.of(context).size;
      final maxWidth = screenSize.width - _position.dx - 16;
      final maxHeight = screenSize.height - _position.dy - 100;

      _width = _width.clamp(_minWidth, maxWidth);
      _height = _height.clamp(_minHeight, maxHeight);
    });
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