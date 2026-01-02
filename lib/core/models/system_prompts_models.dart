import 'package:json_annotation/json_annotation.dart';

part 'system_prompts_models.g.dart';

// ============================================================================
// Prompt Section Models
// ============================================================================

@JsonSerializable()
class PromptSection {
  final int id;
  @JsonKey(name: 'section_id')
  final String sectionId;
  @JsonKey(name: 'section_type')
  final String sectionType;
  final String name;
  final String content;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'is_global')
  final bool isGlobal;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  PromptSection({
    required this.id,
    required this.sectionId,
    required this.sectionType,
    required this.name,
    required this.content,
    this.displayOrder = 0,
    this.isGlobal = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PromptSection.fromJson(Map<String, dynamic> json) =>
      _$PromptSectionFromJson(json);

  Map<String, dynamic> toJson() => _$PromptSectionToJson(this);

  PromptSection copyWith({
    int? id,
    String? sectionId,
    String? sectionType,
    String? name,
    String? content,
    int? displayOrder,
    bool? isGlobal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromptSection(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      sectionType: sectionType ?? this.sectionType,
      name: name ?? this.name,
      content: content ?? this.content,
      displayOrder: displayOrder ?? this.displayOrder,
      isGlobal: isGlobal ?? this.isGlobal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class PromptSectionCreate {
  @JsonKey(name: 'section_id')
  final String sectionId;
  @JsonKey(name: 'section_type')
  final String sectionType;
  final String name;
  final String content;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'is_global')
  final bool isGlobal;

  PromptSectionCreate({
    required this.sectionId,
    required this.sectionType,
    required this.name,
    required this.content,
    this.displayOrder = 0,
    this.isGlobal = false,
  });

  factory PromptSectionCreate.fromJson(Map<String, dynamic> json) =>
      _$PromptSectionCreateFromJson(json);

  Map<String, dynamic> toJson() => _$PromptSectionCreateToJson(this);
}

@JsonSerializable()
class PromptSectionUpdate {
  final String? name;
  final String? content;
  @JsonKey(name: 'display_order')
  final int? displayOrder;
  @JsonKey(name: 'is_global')
  final bool? isGlobal;

  PromptSectionUpdate({
    this.name,
    this.content,
    this.displayOrder,
    this.isGlobal,
  });

  factory PromptSectionUpdate.fromJson(Map<String, dynamic> json) =>
      _$PromptSectionUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$PromptSectionUpdateToJson(this);
}

// ============================================================================
// System Prompt Models
// ============================================================================

@JsonSerializable()
class SystemPrompt {
  final int id;
  @JsonKey(name: 'agent_id')
  final String agentId;
  final String name;
  final String content;
  @JsonKey(name: 'section_ids')
  final List<String> sectionIds;
  final int version;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'tools_position')
  final String toolsPosition;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  SystemPrompt({
    required this.id,
    required this.agentId,
    required this.name,
    required this.content,
    this.sectionIds = const [],
    this.version = 1,
    this.isActive = false,
    this.toolsPosition = 'end',
    this.createdAt,
  });

  factory SystemPrompt.fromJson(Map<String, dynamic> json) =>
      _$SystemPromptFromJson(json);

  Map<String, dynamic> toJson() => _$SystemPromptToJson(this);

  SystemPrompt copyWith({
    int? id,
    String? agentId,
    String? name,
    String? content,
    List<String>? sectionIds,
    int? version,
    bool? isActive,
    String? toolsPosition,
    DateTime? createdAt,
  }) {
    return SystemPrompt(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      name: name ?? this.name,
      content: content ?? this.content,
      sectionIds: sectionIds ?? this.sectionIds,
      version: version ?? this.version,
      isActive: isActive ?? this.isActive,
      toolsPosition: toolsPosition ?? this.toolsPosition,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@JsonSerializable()
class SystemPromptCreate {
  final String name;
  final String content;
  @JsonKey(name: 'section_ids')
  final List<String> sectionIds;
  @JsonKey(name: 'tools_position')
  final String toolsPosition;
  @JsonKey(name: 'is_active')
  final bool isActive;

  SystemPromptCreate({
    required this.name,
    required this.content,
    this.sectionIds = const [],
    this.toolsPosition = 'end',
    this.isActive = false,
  });

  factory SystemPromptCreate.fromJson(Map<String, dynamic> json) =>
      _$SystemPromptCreateFromJson(json);

  Map<String, dynamic> toJson() => _$SystemPromptCreateToJson(this);
}

@JsonSerializable()
class SystemPromptUpdate {
  final String? name;
  final String? content;
  @JsonKey(name: 'section_ids')
  final List<String>? sectionIds;
  @JsonKey(name: 'tools_position')
  final String? toolsPosition;

  SystemPromptUpdate({
    this.name,
    this.content,
    this.sectionIds,
    this.toolsPosition,
  });

  factory SystemPromptUpdate.fromJson(Map<String, dynamic> json) =>
      _$SystemPromptUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$SystemPromptUpdateToJson(this);
}

// ============================================================================
// Prompt Version Models
// ============================================================================

@JsonSerializable()
class PromptVersion {
  final int id;
  @JsonKey(name: 'prompt_id')
  final int promptId;
  final int version;
  final String content;
  @JsonKey(name: 'section_ids')
  final List<String> sectionIds;
  @JsonKey(name: 'change_reason')
  final String? changeReason;
  @JsonKey(name: 'changed_by')
  final String? changedBy;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  PromptVersion({
    required this.id,
    required this.promptId,
    required this.version,
    required this.content,
    this.sectionIds = const [],
    this.changeReason,
    this.changedBy,
    this.createdAt,
  });

  factory PromptVersion.fromJson(Map<String, dynamic> json) =>
      _$PromptVersionFromJson(json);

  Map<String, dynamic> toJson() => _$PromptVersionToJson(this);
}

// ============================================================================
// Prompt Preview Models
// ============================================================================

@JsonSerializable()
class PromptPreview {
  @JsonKey(name: 'agent_id')
  final String agentId;
  final int version;
  @JsonKey(name: 'full_prompt')
  final String fullPrompt;
  @JsonKey(name: 'sections_content')
  final String sectionsContent;
  @JsonKey(name: 'main_content')
  final String mainContent;
  @JsonKey(name: 'tools_section')
  final String toolsSection;
  @JsonKey(name: 'total_length')
  final int totalLength;

  PromptPreview({
    required this.agentId,
    required this.version,
    required this.fullPrompt,
    required this.sectionsContent,
    required this.mainContent,
    required this.toolsSection,
    required this.totalLength,
  });

  factory PromptPreview.fromJson(Map<String, dynamic> json) =>
      _$PromptPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$PromptPreviewToJson(this);
}

// ============================================================================
// Delete Response
// ============================================================================

@JsonSerializable()
class DeleteResponse {
  final bool success;
  final String deleted;

  DeleteResponse({
    required this.success,
    required this.deleted,
  });

  factory DeleteResponse.fromJson(Map<String, dynamic> json) =>
      _$DeleteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteResponseToJson(this);
}

// ============================================================================
// Agent Info (for UI)
// ============================================================================

class AgentInfo {
  final String id;
  final String name;
  final String icon;

  const AgentInfo({
    required this.id,
    required this.name,
    required this.icon,
  });

  static const List<AgentInfo> allAgents = [
    AgentInfo(id: 'primary', name: 'Primary Agent', icon: 'hub'),
    AgentInfo(id: 'browser', name: 'Browser Agent', icon: 'language'),
    AgentInfo(id: 'weather', name: 'Weather Agent', icon: 'cloud'),
    AgentInfo(id: 'search', name: 'Search Agent', icon: 'search'),
    AgentInfo(id: 'notes', name: 'Notes Agent', icon: 'note'),
    AgentInfo(id: 'calendar', name: 'Calendar Agent', icon: 'calendar_today'),
    AgentInfo(id: 'calculator', name: 'Calculator Agent', icon: 'calculate'),
  ];

  static AgentInfo? byId(String id) {
    try {
      return allAgents.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ============================================================================
// Section Types
// ============================================================================

class SectionType {
  final String id;
  final String name;

  const SectionType({required this.id, required this.name});

  static const List<SectionType> allTypes = [
    SectionType(id: 'identity', name: 'Identity'),
    SectionType(id: 'guidelines', name: 'Guidelines'),
    SectionType(id: 'context', name: 'Context'),
    SectionType(id: 'tools', name: 'Tools'),
    SectionType(id: 'memory', name: 'Memory'),
    SectionType(id: 'constraints', name: 'Constraints'),
    SectionType(id: 'custom', name: 'Custom'),
  ];
}
