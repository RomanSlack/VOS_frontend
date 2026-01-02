import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vos_app/core/api/system_prompts_api.dart';
import 'package:vos_app/core/models/system_prompts_models.dart';
import 'system_prompts_event.dart';
import 'system_prompts_state.dart';

class SystemPromptsBloc extends Bloc<SystemPromptsEvent, SystemPromptsState> {
  final SystemPromptsApi _api;

  SystemPromptsBloc(this._api) : super(const SystemPromptsInitial()) {
    on<LoadSections>(_onLoadSections);
    on<LoadAgentPrompts>(_onLoadAgentPrompts);
    on<LoadVersions>(_onLoadVersions);
    on<LoadPreview>(_onLoadPreview);
    on<CreateSection>(_onCreateSection);
    on<UpdateSection>(_onUpdateSection);
    on<DeleteSection>(_onDeleteSection);
    on<CreatePrompt>(_onCreatePrompt);
    on<UpdatePrompt>(_onUpdatePrompt);
    on<ActivatePrompt>(_onActivatePrompt);
    on<RollbackPrompt>(_onRollbackPrompt);
    on<SelectAgent>(_onSelectAgent);
    on<SwitchTab>(_onSwitchTab);
    on<ClearError>(_onClearError);
  }

  SystemPromptsLoaded? get _currentLoaded {
    if (state is SystemPromptsLoaded) {
      return state as SystemPromptsLoaded;
    }
    if (state is SystemPromptsError) {
      return (state as SystemPromptsError).previousState;
    }
    if (state is VersionsLoaded) {
      return (state as VersionsLoaded).baseState;
    }
    if (state is PreviewLoaded) {
      return (state as PreviewLoaded).baseState;
    }
    if (state is OperationSuccess) {
      return (state as OperationSuccess).updatedState;
    }
    return null;
  }

  Future<void> _onLoadSections(
    LoadSections event,
    Emitter<SystemPromptsState> emit,
  ) async {
    emit(const SystemPromptsLoading());
    try {
      final sections = await _api.listSections();
      final agentId = _currentLoaded?.selectedAgentId ?? 'primary';
      List<SystemPrompt> prompts = [];
      try {
        prompts = await _api.listAgentPrompts(agentId);
      } catch (_) {
        // Agent might not have prompts yet
      }
      emit(SystemPromptsLoaded(
        sections: sections,
        prompts: prompts,
        selectedAgentId: agentId,
      ));
    } catch (e) {
      emit(SystemPromptsError('Failed to load sections: $e'));
    }
  }

  Future<void> _onLoadAgentPrompts(
    LoadAgentPrompts event,
    Emitter<SystemPromptsState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) {
      emit(const SystemPromptsLoading());
    } else {
      emit(current.copyWith(isOperationInProgress: true));
    }

    try {
      final prompts = await _api.listAgentPrompts(event.agentId);
      final sections = current?.sections ?? await _api.listSections();
      emit(SystemPromptsLoaded(
        sections: sections,
        prompts: prompts,
        selectedAgentId: event.agentId,
        selectedTabIndex: current?.selectedTabIndex ?? 0,
      ));
    } catch (e) {
      emit(SystemPromptsError(
        'Failed to load prompts: $e',
        previousState: current,
      ));
    }
  }

  Future<void> _onLoadVersions(
    LoadVersions event,
    Emitter<SystemPromptsState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;

    try {
      final versions = await _api.listVersions(event.promptId);
      emit(VersionsLoaded(
        versions: versions,
        promptId: event.promptId,
        baseState: current,
      ));
    } catch (e) {
      emit(SystemPromptsError(
        'Failed to load versions: $e',
        previousState: current,
      ));
    }
  }

  Future<void> _onLoadPreview(
    LoadPreview event,
    Emitter<SystemPromptsState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;

    try {
      final preview = await _api.previewPrompt(event.promptId);
      emit(PreviewLoaded(
        preview: preview,
        baseState: current,
      ));
    } catch (e) {
      emit(SystemPromptsError(
        'Failed to load preview: $e',
        previousState: current,
      ));
    }
  }

  Future<void> _onCreateSection(
    CreateSection event,
    Emitter<SystemPromptsState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;

    emit(current.copyWith(isOperationInProgress: true));

    try {
      final section = await _api.createSection(event.section);
      final sections = [...current.sections, section];
      emit(OperationSuccess(
        message: 'Section created',
        updatedState: current.copyWith(
          sections: sections,
          isOperationInProgress: false,
        ),
      ));
    } catch (e) {
      emit(SystemPromptsError(
        'Failed to create section: $e',
        previousState: current,
      ));
    }
  }

  Future<void> _onUpdateSection(
    UpdateSection event,
    Emitter<SystemPromptsState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;

    emit(current.copyWith(isOperationInProgress: true));

    try {
      final updated = await _api.updateSection(event.sectionId, event.update);
      final sections = current.sections.map((s) {
        return s.sectionId == event.sectionId ? updated : s;
      }).toList();
      emit(OperationSuccess(
        message: 'Section updated',
        updatedState: current.copyWith(
          sections: sections,
          isOperationInProgress: false,
        ),
      ));
    } catch (e) {
      emit(SystemPromptsError(
        'Failed to update section: $e',
        previousState: current,
      ));
    }
  }

  Future<void> _onDeleteSection(
    DeleteSection event,
    Emitter<SystemPromptsState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;

    emit(current.copyWith(isOperationInProgress: true));

    try {
      await _api.deleteSection(event.sectionId);
      final sections =
          current.sections.where((s) => s.sectionId != event.sectionId).toList();
      emit(OperationSuccess(
        message: 'Section deleted',
        updatedState: current.copyWith(
          sections: sections,
          isOperationInProgress: false,
        ),
      ));
    } catch (e) {
      emit(SystemPromptsError(
        'Failed to delete section: $e',
        previousState: current,
      ));
    }
  }

  Future<void> _onCreatePrompt(
    CreatePrompt event,
    Emitter<SystemPromptsState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;

    emit(current.copyWith(isOperationInProgress: true));

    try {
      final prompt = await _api.createPrompt(event.agentId, event.prompt);
      final prompts = [...current.prompts, prompt];
      emit(OperationSuccess(
        message: 'Prompt created',
        updatedState: current.copyWith(
          prompts: prompts,
          isOperationInProgress: false,
        ),
      ));
    } catch (e) {
      emit(SystemPromptsError(
        'Failed to create prompt: $e',
        previousState: current,
      ));
    }
  }

  Future<void> _onUpdatePrompt(
    UpdatePrompt event,
    Emitter<SystemPromptsState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;

    emit(current.copyWith(isOperationInProgress: true));

    try {
      final updated = await _api.updatePrompt(event.promptId, event.update);
      final prompts = current.prompts.map((p) {
        return p.id == event.promptId ? updated : p;
      }).toList();
      emit(OperationSuccess(
        message: 'Prompt updated (v${updated.version})',
        updatedState: current.copyWith(
          prompts: prompts,
          isOperationInProgress: false,
        ),
      ));
    } catch (e) {
      emit(SystemPromptsError(
        'Failed to update prompt: $e',
        previousState: current,
      ));
    }
  }

  Future<void> _onActivatePrompt(
    ActivatePrompt event,
    Emitter<SystemPromptsState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;

    emit(current.copyWith(isOperationInProgress: true));

    try {
      await _api.activatePrompt(event.promptId);
      // Reload prompts to get updated active states
      final prompts = await _api.listAgentPrompts(current.selectedAgentId);
      emit(OperationSuccess(
        message: 'Prompt activated',
        updatedState: current.copyWith(
          prompts: prompts,
          isOperationInProgress: false,
        ),
      ));
    } catch (e) {
      emit(SystemPromptsError(
        'Failed to activate prompt: $e',
        previousState: current,
      ));
    }
  }

  Future<void> _onRollbackPrompt(
    RollbackPrompt event,
    Emitter<SystemPromptsState> emit,
  ) async {
    final current = _currentLoaded;
    if (current == null) return;

    emit(current.copyWith(isOperationInProgress: true));

    try {
      final updated = await _api.rollbackVersion(event.promptId, event.version);
      final prompts = current.prompts.map((p) {
        return p.id == event.promptId ? updated : p;
      }).toList();
      emit(OperationSuccess(
        message: 'Rolled back to v${event.version}',
        updatedState: current.copyWith(
          prompts: prompts,
          isOperationInProgress: false,
        ),
      ));
    } catch (e) {
      emit(SystemPromptsError(
        'Failed to rollback: $e',
        previousState: current,
      ));
    }
  }

  Future<void> _onSelectAgent(
    SelectAgent event,
    Emitter<SystemPromptsState> emit,
  ) async {
    add(LoadAgentPrompts(event.agentId));
  }

  void _onSwitchTab(
    SwitchTab event,
    Emitter<SystemPromptsState> emit,
  ) {
    final current = _currentLoaded;
    if (current == null) return;

    emit(current.copyWith(selectedTabIndex: event.tabIndex));
  }

  void _onClearError(
    ClearError event,
    Emitter<SystemPromptsState> emit,
  ) {
    if (state is SystemPromptsError) {
      final errorState = state as SystemPromptsError;
      if (errorState.previousState != null) {
        emit(errorState.previousState!);
      } else {
        emit(const SystemPromptsInitial());
      }
    }
  }
}
