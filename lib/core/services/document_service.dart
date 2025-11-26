import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vos_app/core/api/document_api.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/models/document_models.dart';
import 'package:vos_app/core/services/auth_service.dart';
import 'package:vos_app/core/services/session_service.dart';
import 'package:vos_app/core/di/injection.dart';

/// Service for managing documents
class DocumentService extends ChangeNotifier {
  late final Dio _dio;
  late final DocumentApi _api;
  final SessionService _sessionService = SessionService();

  // Cached documents for current session
  final List<Document> _documents = [];
  bool _isLoading = false;
  String? _error;
  int _total = 0;

  // Document cache by ID
  final Map<String, Document> _documentCache = {};

  // Notifier for new documents (for real-time updates)
  final StreamController<Document> _newDocumentController =
      StreamController<Document>.broadcast();

  DocumentService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['X-API-Key'] = AppConfig.apiKey;

          if (AppConfig.apiBaseUrl.contains('10.0.2.2')) {
            options.headers['Host'] = 'localhost:8000';
          }

          final authService = getIt<AuthService>();
          final token = await authService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
      ),
    );

    _api = DocumentApi(_dio);
  }

  // Getters
  List<Document> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _total;
  bool get hasMore => _documents.length < _total;
  int get documentCount => _documents.length;
  Stream<Document> get newDocumentStream => _newDocumentController.stream;

  /// Load documents for the current session
  Future<void> loadDocuments({
    bool refresh = false,
    int limit = 20,
  }) async {
    if (_isLoading) return;

    final sessionId = await _sessionService.getSessionId();

    if (refresh) {
      _documents.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.listDocuments(
        sessionId: sessionId,
        limit: limit,
        offset: refresh ? 0 : _documents.length,
      );

      if (refresh) {
        _documents.clear();
      }

      _documents.addAll(response.documents);
      _total = response.total;

      // Update cache
      for (final doc in response.documents) {
        _documentCache[doc.documentId] = doc;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      debugPrint('Error loading documents: $e');
      notifyListeners();
    }
  }

  /// Load more documents (pagination)
  Future<void> loadMore({int limit = 20}) async {
    if (_isLoading || !hasMore) return;
    await loadDocuments(refresh: false, limit: limit);
  }

  /// Get a specific document by ID
  Future<Document?> getDocument(String documentId) async {
    // Check cache first
    if (_documentCache.containsKey(documentId)) {
      return _documentCache[documentId];
    }

    try {
      final document = await _api.getDocument(documentId);
      _documentCache[documentId] = document;
      return document;
    } catch (e) {
      debugPrint('Error getting document $documentId: $e');
      return null;
    }
  }

  /// Create a new document
  Future<Document?> createDocument({
    required String title,
    required String content,
    String? contentType,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final sessionId = await _sessionService.getSessionId();

      final request = CreateDocumentRequest(
        title: title,
        content: content,
        contentType: contentType,
        tags: tags,
        sessionId: sessionId,
        metadata: metadata,
      );

      final document = await _api.createDocument(request);

      // Add to cache and list
      _documentCache[document.documentId] = document;
      _documents.insert(0, document);
      _total++;
      notifyListeners();

      return document;
    } catch (e) {
      debugPrint('Error creating document: $e');
      return null;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(String documentId) async {
    try {
      await _api.deleteDocument(documentId);

      // Remove from cache and list
      _documentCache.remove(documentId);
      _documents.removeWhere((d) => d.documentId == documentId);
      _total--;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }

  /// Filter documents by tags
  Future<List<Document>> getDocumentsByTags(List<String> tags) async {
    try {
      final sessionId = await _sessionService.getSessionId();

      final response = await _api.listDocuments(
        sessionId: sessionId,
        tags: tags.join(','),
        limit: 100,
      );

      return response.documents;
    } catch (e) {
      debugPrint('Error filtering documents by tags: $e');
      return [];
    }
  }

  /// Filter documents by agent
  Future<List<Document>> getDocumentsByAgent(String agentId) async {
    try {
      final sessionId = await _sessionService.getSessionId();

      final response = await _api.listDocuments(
        sessionId: sessionId,
        creatorAgentId: agentId,
        limit: 100,
      );

      return response.documents;
    } catch (e) {
      debugPrint('Error filtering documents by agent: $e');
      return [];
    }
  }

  /// Handle document created notification from WebSocket
  void handleDocumentCreated(DocumentCreatedNotification notification) async {
    // Fetch the full document
    final document = await getDocument(notification.documentId);
    if (document != null) {
      // Add to list if not already present
      if (!_documents.any((d) => d.documentId == document.documentId)) {
        _documents.insert(0, document);
        _total++;
        notifyListeners();
      }

      // Notify listeners through stream
      _newDocumentController.add(document);
    }
  }

  /// Search documents locally
  List<Document> searchLocally(String query) {
    final lowerQuery = query.toLowerCase();
    return _documents.where((doc) {
      return doc.title.toLowerCase().contains(lowerQuery) ||
          (doc.content?.toLowerCase().contains(lowerQuery) ?? false) ||
          (doc.tags?.any((tag) => tag.toLowerCase().contains(lowerQuery)) ?? false);
    }).toList();
  }

  /// Get unique tags from all documents
  Set<String> get allTags {
    final tags = <String>{};
    for (final doc in _documents) {
      if (doc.tags != null) {
        tags.addAll(doc.tags!);
      }
    }
    return tags;
  }

  /// Get unique agent IDs from all documents
  Set<String> get allAgentIds {
    final agents = <String>{};
    for (final doc in _documents) {
      if (doc.sourceAgentId != null) {
        agents.add(doc.sourceAgentId!);
      }
    }
    return agents;
  }

  /// Clear all cached data
  void clearCache() {
    _documents.clear();
    _documentCache.clear();
    _total = 0;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _newDocumentController.close();
    super.dispose();
  }
}
