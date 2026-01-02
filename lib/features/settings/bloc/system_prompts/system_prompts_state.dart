import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/system_prompts_models.dart';

abstract class SystemPromptsState extends Equatable {
  const SystemPromptsState();

  @override
  List<Object?> get props => [];
}

class SystemPromptsInitial extends SystemPromptsState {
  const SystemPromptsInitial();
}

class SystemPromptsLoading extends SystemPromptsState {
  const SystemPromptsLoading();
}

class SystemPromptsLoaded extends SystemPromptsState {
  final List<PromptSection> sections;
  final List<SystemPrompt> prompts;
  final String selectedAgentId;
  final int selectedTabIndex; // 0 = Prompts, 1 = Sections
  final bool isOperationInProgress;

  const SystemPromptsLoaded({
    required this.sections,
    required this.prompts,
    this.selectedAgentId = 'primary',
    this.selectedTabIndex = 0,
    this.isOperationInProgress = false,
  });

  @override
  List<Object?> get props => [
        sections,
        prompts,
        selectedAgentId,
        selectedTabIndex,
        isOperationInProgress,
      ];

  SystemPromptsLoaded copyWith({
    List<PromptSection>? sections,
    List<SystemPrompt>? prompts,
    String? selectedAgentId,
    int? selectedTabIndex,
    bool? isOperationInProgress,
  }) {
    return SystemPromptsLoaded(
      sections: sections ?? this.sections,
      prompts: prompts ?? this.prompts,
      selectedAgentId: selectedAgentId ?? this.selectedAgentId,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      isOperationInProgress:
          isOperationInProgress ?? this.isOperationInProgress,
    );
  }

  SystemPrompt? get activePrompt {
    try {
      return prompts.firstWhere((p) => p.isActive);
    } catch (_) {
      return null;
    }
  }

  List<PromptSection> get sortedSections {
    final sorted = List<PromptSection>.from(sections);
    sorted.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sorted;
  }
}

class SystemPromptsError extends SystemPromptsState {
  final String message;
  final SystemPromptsLoaded? previousState;

  const SystemPromptsError(this.message, {this.previousState});

  @override
  List<Object?> get props => [message, previousState];
}

// ============================================================================
// Dialog States
// ============================================================================

class VersionsLoaded extends SystemPromptsState {
  final List<PromptVersion> versions;
  final int promptId;
  final SystemPromptsLoaded baseState;

  const VersionsLoaded({
    required this.versions,
    required this.promptId,
    required this.baseState,
  });

  @override
  List<Object?> get props => [versions, promptId, baseState];
}

class PreviewLoaded extends SystemPromptsState {
  final PromptPreview preview;
  final SystemPromptsLoaded baseState;

  const PreviewLoaded({
    required this.preview,
    required this.baseState,
  });

  @override
  List<Object?> get props => [preview, baseState];
}

// ============================================================================
// Operation Success States
// ============================================================================

class OperationSuccess extends SystemPromptsState {
  final String message;
  final SystemPromptsLoaded updatedState;

  const OperationSuccess({
    required this.message,
    required this.updatedState,
  });

  @override
  List<Object?> get props => [message, updatedState];
}
