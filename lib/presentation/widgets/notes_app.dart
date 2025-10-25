import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasContent = false;
  int _characterCount = 0;
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    setState(() {
      _hasContent = text.isNotEmpty;
      _characterCount = text.length;
      _lineCount = text.isEmpty ? 1 : text.split('\n').length;
    });
  }

  void _clearText() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF303030),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: const Text(
          'Clear Document',
          style: TextStyle(
            color: Color(0xFFEDEDED),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to clear all text? This action cannot be undone.',
          style: TextStyle(
            color: Color(0xFF757575),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF757575)),
            ),
          ),
          TextButton(
            onPressed: () {
              _textController.clear();
              Navigator.pop(context);
              _focusNode.requestFocus();
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Color(0xFFFF5722)),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAll() {
    _textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _textController.text.length,
    );
  }

  void _copyText() {
    if (_textController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _textController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Text copied to clipboard',
            style: TextStyle(color: Color(0xFFEDEDED)),
          ),
          backgroundColor: const Color(0xFF424242),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        color: const Color(0xFF212121),
        child: Column(
        children: [
          // Header with title and actions
          _buildHeader(),

          // Text editor area
          Expanded(
            child: _buildTextEditor(),
          ),

          // Status bar
          _buildStatusBar(),
        ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF303030),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title
          const Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Notes',
                  style: TextStyle(
                    color: Color(0xFFEDEDED),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              _buildHeaderButton(
                icon: Icons.select_all,
                tooltip: 'Select All',
                onPressed: _hasContent ? _selectAll : null,
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(
                icon: Icons.copy_outlined,
                tooltip: 'Copy All',
                onPressed: _hasContent ? _copyText : null,
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(
                icon: Icons.clear_outlined,
                tooltip: 'Clear All',
                onPressed: _hasContent ? _clearText : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isEnabled
            ? const Color(0xFF424242)
            : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withOpacity(isEnabled ? 0.1 : 0.05),
            width: 1,
          ),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: isEnabled
              ? const Color(0xFFEDEDED)
              : const Color(0xFF424242),
            size: 16,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildTextEditor() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(
          color: Color(0xFFEDEDED),
          fontSize: 14,
          height: 1.5,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          hintText: 'Start typing your notes here...',
          hintStyle: TextStyle(
            color: const Color(0xFF757575).withOpacity(0.7),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
        ),
        cursorColor: const Color(0xFFFF9800),
        cursorWidth: 2,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Document status
          Icon(
            _hasContent ? Icons.edit_outlined : Icons.description_outlined,
            color: _hasContent ? const Color(0xFFFF9800) : const Color(0xFF424242),
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            _hasContent ? 'Editing' : 'Empty document',
            style: TextStyle(
              color: _hasContent ? const Color(0xFFEDEDED) : const Color(0xFF757575),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Spacer(),

          // Statistics
          if (_hasContent) ...[
            Text(
              'Lines: $_lineCount',
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Characters: $_characterCount',
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}