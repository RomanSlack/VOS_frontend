import 'package:flutter/material.dart';
import 'package:vos_app/core/models/document_models.dart';
import 'package:vos_app/core/services/document_service.dart';
import 'package:vos_app/core/di/injection.dart';
import 'package:vos_app/presentation/widgets/document_viewer.dart';

/// Widget that renders clickable document references in text
class DocumentReferenceText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;

  const DocumentReferenceText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
  });

  @override
  Widget build(BuildContext context) {
    final references = DocumentReference.extractFromText(text);

    if (references.isEmpty) {
      return Text(text, style: style);
    }

    // Build text spans with clickable document references
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final ref in references) {
      // Add text before the reference
      if (ref.startIndex > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, ref.startIndex),
          style: style,
        ));
      }

      // Add the document reference as a clickable widget
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _DocumentReferenceChip(
          documentId: ref.documentId,
          style: linkStyle ?? const TextStyle(
            color: Color(0xFF00BCD4),
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF00BCD4),
          ),
        ),
      ));

      lastEnd = ref.endIndex;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }
}

/// Clickable chip for a document reference
class _DocumentReferenceChip extends StatefulWidget {
  final String documentId;
  final TextStyle style;

  const _DocumentReferenceChip({
    required this.documentId,
    required this.style,
  });

  @override
  State<_DocumentReferenceChip> createState() => _DocumentReferenceChipState();
}

class _DocumentReferenceChipState extends State<_DocumentReferenceChip> {
  Document? _document;
  bool _isLoading = false;
  bool _isHovered = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);

    final documentService = getIt<DocumentService>();
    final doc = await documentService.getDocument(widget.documentId);

    if (mounted) {
      setState(() {
        _document = doc;
        _isLoading = false;
      });
    }
  }

  void _showPreview() {
    if (_document == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 8),
          child: Material(
            color: Colors.transparent,
            child: DocumentPreviewCard(
              document: _document!,
              onTap: () {
                _hidePreview();
                _openDocument();
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hidePreview() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _openDocument() {
    if (_document == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentViewer(document: _document!),
      ),
    );
  }

  @override
  void dispose() {
    _hidePreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          if (_document != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_isHovered && mounted) {
                _showPreview();
              }
            });
          }
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _hidePreview();
        },
        child: GestureDetector(
          onTap: _openDocument,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _isHovered
                  ? const Color(0xFF00BCD4).withOpacity(0.2)
                  : const Color(0xFF00BCD4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFF00BCD4).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)),
                    ),
                  )
                else
                  const Icon(
                    Icons.description,
                    size: 12,
                    color: Color(0xFF00BCD4),
                  ),
                const SizedBox(width: 4),
                Text(
                  _document?.title ?? widget.documentId,
                  style: widget.style.copyWith(
                    fontSize: 12,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline document reference button for use in markdown
class DocumentReferenceButton extends StatefulWidget {
  final String documentId;

  const DocumentReferenceButton({
    super.key,
    required this.documentId,
  });

  @override
  State<DocumentReferenceButton> createState() => _DocumentReferenceButtonState();
}

class _DocumentReferenceButtonState extends State<DocumentReferenceButton> {
  Document? _document;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);

    final documentService = getIt<DocumentService>();
    final doc = await documentService.getDocument(widget.documentId);

    if (mounted) {
      setState(() {
        _document = doc;
        _isLoading = false;
      });
    }
  }

  void _openDocument() {
    if (_document == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentViewer(document: _document!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _document != null ? _openDocument : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF00BCD4).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF00BCD4)),
                  ),
                )
              else
                const Icon(
                  Icons.description,
                  size: 16,
                  color: Color(0xFF00BCD4),
                ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _document?.title ?? 'Loading document...',
                    style: const TextStyle(
                      color: Color(0xFF00BCD4),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_document?.sourceAgentId != null)
                    Text(
                      'From: ${_document!.sourceAgentDisplayName}',
                      style: const TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.open_in_new,
                size: 14,
                color: Color(0xFF00BCD4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
