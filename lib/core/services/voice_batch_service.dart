import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:vos_app/core/models/voice_models.dart';
import 'package:vos_app/core/config/app_config.dart';
import 'package:vos_app/core/api/voice_api.dart';

/// Status of batch recording
enum BatchRecordingStatus {
  idle,
  recording,
  uploading,
  transcribing,
  completed,
  error,
}

/// Voice batch service for hold-to-record functionality
/// Records audio to file, uploads for batch transcription
class VoiceBatchService {
  // API client
  late final Dio _dio;
  late final VoiceApi _voiceApi;

  // Audio recording
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;
  Uint8List? _recordedBytes; // For web platform
  DateTime? _recordingStartTime;

  // Transcription state
  BatchRecordingStatus _status = BatchRecordingStatus.idle;
  String? _currentJobId;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  bool _isFetchingResult = false; // Prevent duplicate result fetching
  static const int _maxPollAttempts = 60; // 60 seconds max polling
  static const Duration _pollInterval = Duration(seconds: 1);

  // JWT token for authentication
  String? _authToken;

  // Session ID for routing agent response to correct conversation
  String? _sessionId;

  VoiceBatchService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.voiceApiBaseUrl,
    ));

    _voiceApi = VoiceApi(_dio, baseUrl: AppConfig.voiceApiBaseUrl);
  }

  // Stream controllers for broadcasting events
  final _statusController = StreamController<BatchRecordingStatus>.broadcast();
  final _transcriptionResultController =
      StreamController<BatchTranscriptionResult>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _recordingDurationController = StreamController<Duration>.broadcast();

  /// Stream of batch recording status changes
  Stream<BatchRecordingStatus> get statusStream => _statusController.stream;

  /// Stream of transcription results
  Stream<BatchTranscriptionResult> get transcriptionResultStream =>
      _transcriptionResultController.stream;

  /// Stream of error messages
  Stream<String> get errorStream => _errorController.stream;

  /// Stream of recording duration updates
  Stream<Duration> get recordingDurationStream =>
      _recordingDurationController.stream;

  /// Current recording status
  BatchRecordingStatus get status => _status;

  /// Is currently recording
  bool get isRecording => _isRecording;

  /// Current recording duration
  Duration? get recordingDuration {
    if (_recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Set authentication token and session ID (from VoiceService)
  /// Stores the token with Bearer prefix for Authorization header
  void setAuthToken(String token, {String? sessionId}) {
    _authToken = 'Bearer $token';
    _sessionId = sessionId;
    debugPrint('Batch service: auth token set, length: ${_authToken!.length}, sessionId: $_sessionId');
  }

  /// Start recording audio to file
  Future<void> startRecording() async {
    if (_isRecording) {
      debugPrint('Already recording');
      return;
    }

    try {
      // Check microphone permission
      if (!await _recorder.hasPermission()) {
        _updateStatus(BatchRecordingStatus.error);
        _errorController.add('Microphone permission denied');
        return;
      }

      // Start recording
      if (kIsWeb) {
        // On web, provide a virtual path (record package needs it)
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc, // AAC for smaller file size
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 128000,
          ),
          path: 'batch_recording_$timestamp.m4a',
        );
        debugPrint('Started batch recording (web mode)');
      } else {
        // On mobile, record to file
        final String filePath = await _getTempFilePath();
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 128000,
          ),
          path: filePath,
        );
        _currentRecordingPath = filePath;
        debugPrint('Started batch recording to: $filePath');
      }

      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _updateStatus(BatchRecordingStatus.recording);

      // Start duration updates (every 100ms)
      _startDurationUpdates();
    } catch (e) {
      debugPrint('Error starting batch recording: $e');
      _updateStatus(BatchRecordingStatus.error);
      _errorController.add('Failed to start recording: $e');
    }
  }

  /// Stop recording and upload for transcription
  Future<void> stopRecordingAndUpload() async {
    if (!_isRecording) {
      debugPrint('Not currently recording');
      return;
    }

    try {
      _isRecording = false;
      _recordingStartTime = null;
      _stopDurationUpdates();

      if (kIsWeb) {
        // On web, stop returns a blob URL string
        final String? blobUrl = await _recorder.stop();

        if (blobUrl == null || blobUrl.isEmpty) {
          throw Exception('Recording blob URL is null or empty');
        }

        debugPrint('Stopped batch recording. Got blob URL: $blobUrl');

        // Fetch bytes from blob URL and upload
        await _uploadBlobUrl(blobUrl);
      } else {
        // On mobile, get file path
        final String? path = await _recorder.stop();

        if (path == null || _currentRecordingPath == null) {
          throw Exception('Recording path is null');
        }

        debugPrint('Stopped batch recording. File saved at: $path');

        // Upload file for transcription
        await _uploadAndTranscribeFile(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _updateStatus(BatchRecordingStatus.error);
      _errorController.add('Failed to stop recording: $e');
      _cleanupRecording();
    }
  }

  /// Cancel recording without uploading
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();
      _isRecording = false;
      _recordingStartTime = null;
      _stopDurationUpdates();
      _cleanupRecording();
      _updateStatus(BatchRecordingStatus.idle);

      debugPrint('Batch recording cancelled');
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  /// Upload audio file and start transcription (mobile)
  Future<void> _uploadAndTranscribeFile(String filePath) async {
    try {
      _updateStatus(BatchRecordingStatus.uploading);

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Recording file not found');
      }

      // Get auth token
      if (_authToken == null) {
        throw Exception('No authentication token available');
      }

      debugPrint('Uploading audio file for transcription...');

      // Upload file
      final job = await _voiceApi.uploadAudioForTranscription(
        file,
        _authToken!,
      );

      _currentJobId = job.jobId;
      debugPrint('Upload successful. Job ID: ${job.jobId}');

      // Delete local file after successful upload
      await _deleteFile(filePath);
      _currentRecordingPath = null;

      // Start polling for result
      _updateStatus(BatchRecordingStatus.transcribing);
      _startPolling(job.jobId);
    } catch (e) {
      debugPrint('Error uploading audio: $e');
      _updateStatus(BatchRecordingStatus.error);
      _errorController.add('Failed to upload audio: $e');
      _cleanupRecording();
    }
  }

  /// Upload blob URL for transcription (web)
  Future<void> _uploadBlobUrl(String blobUrl) async {
    try {
      _updateStatus(BatchRecordingStatus.uploading);

      // Get auth token
      if (_authToken == null) {
        throw Exception('No authentication token available');
      }

      debugPrint('Fetching blob and uploading for transcription...');

      // Fetch the blob from URL using Dio
      final response = await Dio().get<List<int>>(
        blobUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList(response.data!);
      debugPrint('Fetched ${bytes.length} bytes from blob URL');

      // Upload using the bytes method
      await _uploadAndTranscribeBytes(bytes);
    } catch (e) {
      debugPrint('Error uploading blob: $e');
      _updateStatus(BatchRecordingStatus.error);
      _errorController.add('Failed to upload audio: $e');
      _cleanupRecording();
    }
  }

  /// Upload audio bytes and start transcription (web)
  Future<void> _uploadAndTranscribeBytes(Uint8List bytes) async {
    try {
      _updateStatus(BatchRecordingStatus.uploading);

      // Get auth token
      if (_authToken == null) {
        throw Exception('No authentication token available');
      }

      debugPrint('Uploading audio bytes for transcription...');
      debugPrint('Auth token set: ${_authToken != null}, length: ${_authToken?.length ?? 0}');

      // Create multipart file from bytes
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: 'recording_$timestamp.m4a',
      );

      // Upload using Dio directly since VoiceApi expects File
      // Include session_id so agent response routes to correct conversation
      final formData = FormData.fromMap({
        'file': multipartFile,
        if (_sessionId != null) 'session_id': _sessionId,
      });

      final response = await _dio.post(
        '/api/v1/transcription/upload',
        data: formData,
        options: Options(
          headers: {
            'Authorization': _authToken ?? '',
          },
        ),
      );

      final job = BatchTranscriptionJob.fromJson(response.data);
      _currentJobId = job.jobId;
      debugPrint('Upload successful. Job ID: ${job.jobId}');

      // Clear recorded bytes
      _recordedBytes = null;

      // Start polling for result
      _updateStatus(BatchRecordingStatus.transcribing);
      _startPolling(job.jobId);
    } catch (e) {
      debugPrint('Error uploading audio bytes: $e');
      _updateStatus(BatchRecordingStatus.error);
      _errorController.add('Failed to upload audio: $e');
      _cleanupRecording();
    }
  }

  /// Start polling for transcription result
  void _startPolling(String jobId) {
    _pollAttempts = 0;
    _isFetchingResult = false;
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      // Prevent duplicate fetching if already processing result
      if (_isFetchingResult) return;

      _pollAttempts++;

      if (_pollAttempts > _maxPollAttempts) {
        timer.cancel();
        _updateStatus(BatchRecordingStatus.error);
        _errorController.add('Transcription timeout - took too long');
        return;
      }

      try {
        // Check job status
        final statusResponse = await _voiceApi.getTranscriptionStatus(
          jobId,
          _authToken!,
        );

        debugPrint(
            'Poll attempt $_pollAttempts: Status = ${statusResponse.status}');

        if (statusResponse.statusEnum == BatchTranscriptionStatus.completed) {
          // Job completed - get result (only once)
          if (!_isFetchingResult) {
            _isFetchingResult = true;
            timer.cancel();
            await _fetchResult(jobId);
          }
        } else if (statusResponse.statusEnum == BatchTranscriptionStatus.failed) {
          // Job failed
          timer.cancel();
          _updateStatus(BatchRecordingStatus.error);
          _errorController
              .add('Transcription failed: ${statusResponse.error ?? "Unknown error"}');
        }
        // If pending or processing, continue polling
      } catch (e) {
        debugPrint('Error polling transcription status: $e');
        // Continue polling on error (might be temporary network issue)
      }
    });
  }

  /// Fetch transcription result
  Future<void> _fetchResult(String jobId) async {
    try {
      final result = await _voiceApi.getTranscriptionResult(
        jobId,
        _authToken!,
      );

      debugPrint('Transcription result: ${result.text}');

      _updateStatus(BatchRecordingStatus.completed);
      _transcriptionResultController.add(result);
      _currentJobId = null;

      // Return to idle after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      _updateStatus(BatchRecordingStatus.idle);
    } catch (e) {
      debugPrint('Error fetching transcription result: $e');
      _updateStatus(BatchRecordingStatus.error);
      _errorController.add('Failed to get transcription result: $e');
    }
  }

  /// Get temporary file path for recording
  Future<String> _getTempFilePath() async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${tempDir.path}/batch_recording_$timestamp.m4a';
  }

  /// Delete recording file
  Future<void> _deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted recording file: $path');
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  /// Clean up current recording
  Future<void> _cleanupRecording() async {
    if (_currentRecordingPath != null) {
      await _deleteFile(_currentRecordingPath!);
      _currentRecordingPath = null;
    }
    _recordedBytes = null;
  }

  /// Update status and notify listeners
  void _updateStatus(BatchRecordingStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  /// Timer for duration updates
  Timer? _durationTimer;

  /// Start duration updates
  void _startDurationUpdates() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        _recordingDurationController.add(duration);
      }
    });
  }

  /// Stop duration updates
  void _stopDurationUpdates() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// Dispose resources
  Future<void> dispose() async {
    _pollTimer?.cancel();
    _durationTimer?.cancel();
    _recorder.dispose();
    await _statusController.close();
    await _transcriptionResultController.close();
    await _errorController.close();
    await _recordingDurationController.close();
    await _cleanupRecording();
  }
}
