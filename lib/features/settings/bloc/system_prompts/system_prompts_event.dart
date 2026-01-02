import 'package:equatable/equatable.dart';
import 'package:vos_app/core/models/system_prompts_models.dart';

abstract class SystemPromptsEvent extends Equatable {
  const SystemPromptsEvent();

  @override
  List<Object?> get props => [];
}

// ============================================================================
// Load Events
// ============================================================================

class LoadSections extends SystemPromptsEvent {
  const LoadSections();
}

class LoadAgentPrompts extends SystemPromptsEvent {
  final String agentId;

  const LoadAgentPrompts(this.agentId);

  @override
  List<Object?> get props => [agentId];
}

class LoadVersions extends SystemPromptsEvent {
  final int promptId;

  const LoadVersions(this.promptId);

  @override
  List<Object?> get props => [promptId];
}

class LoadPreview extends SystemPromptsEvent {
  final int promptId;

  const LoadPreview(this.promptId);

  @override
  List<Object?> get props => [promptId];
}

// ============================================================================
// Section CRUD Events
// ============================================================================

class CreateSection extends SystemPromptsEvent {
  final PromptSectionCreate section;

  const CreateSection(this.section);

  @override
  List<Object?> get props => [section];
}

class UpdateSection extends SystemPromptsEvent {
  final String sectionId;
  final PromptSectionUpdate update;

  const UpdateSection(this.sectionId, this.update);

  @override
  List<Object?> get props => [sectionId, update];
}

class DeleteSection extends SystemPromptsEvent {
  final String sectionId;

  const DeleteSection(this.sectionId);

  @override
  List<Object?> get props => [sectionId];
}

// ============================================================================
// Prompt CRUD Events
// ============================================================================

class CreatePrompt extends SystemPromptsEvent {
  final String agentId;
  final SystemPromptCreate prompt;

  const CreatePrompt(this.agentId, this.prompt);

  @override
  List<Object?> get props => [agentId, prompt];
}

class UpdatePrompt extends SystemPromptsEvent {
  final int promptId;
  final SystemPromptUpdate update;

  const UpdatePrompt(this.promptId, this.update);

  @override
  List<Object?> get props => [promptId, update];
}

class ActivatePrompt extends SystemPromptsEvent {
  final int promptId;

  const ActivatePrompt(this.promptId);

  @override
  List<Object?> get props => [promptId];
}

class RollbackPrompt extends SystemPromptsEvent {
  final int promptId;
  final int version;

  const RollbackPrompt(this.promptId, this.version);

  @override
  List<Object?> get props => [promptId, version];
}

// ============================================================================
// UI State Events
// ============================================================================

class SelectAgent extends SystemPromptsEvent {
  final String agentId;

  const SelectAgent(this.agentId);

  @override
  List<Object?> get props => [agentId];
}

class SwitchTab extends SystemPromptsEvent {
  final int tabIndex;

  const SwitchTab(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class ClearError extends SystemPromptsEvent {
  const ClearError();
}
