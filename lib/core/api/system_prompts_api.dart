import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vos_app/core/models/system_prompts_models.dart';

part 'system_prompts_api.g.dart';

@RestApi(baseUrl: '')
abstract class SystemPromptsApi {
  factory SystemPromptsApi(Dio dio, {String? baseUrl}) = _SystemPromptsApi;

  // =========================================================================
  // Section Endpoints
  // =========================================================================

  @GET('/api/v1/system-prompts/sections')
  Future<List<PromptSection>> listSections({
    @Query('section_type') String? sectionType,
    @Query('is_global') bool? isGlobal,
  });

  @GET('/api/v1/system-prompts/sections/{sectionId}')
  Future<PromptSection> getSection(@Path('sectionId') String sectionId);

  @POST('/api/v1/system-prompts/sections')
  Future<PromptSection> createSection(@Body() PromptSectionCreate section);

  @PUT('/api/v1/system-prompts/sections/{sectionId}')
  Future<PromptSection> updateSection(
    @Path('sectionId') String sectionId,
    @Body() PromptSectionUpdate update,
  );

  @DELETE('/api/v1/system-prompts/sections/{sectionId}')
  Future<DeleteResponse> deleteSection(@Path('sectionId') String sectionId);

  // =========================================================================
  // Agent Prompt Endpoints
  // =========================================================================

  @GET('/api/v1/system-prompts/agents/{agentId}')
  Future<List<SystemPrompt>> listAgentPrompts(@Path('agentId') String agentId);

  @GET('/api/v1/system-prompts/agents/{agentId}/active')
  Future<SystemPrompt> getActivePrompt(@Path('agentId') String agentId);

  @POST('/api/v1/system-prompts/agents/{agentId}')
  Future<SystemPrompt> createPrompt(
    @Path('agentId') String agentId,
    @Body() SystemPromptCreate prompt,
  );

  // =========================================================================
  // Prompt Management Endpoints
  // =========================================================================

  @GET('/api/v1/system-prompts/{promptId}')
  Future<SystemPrompt> getPrompt(@Path('promptId') int promptId);

  @PUT('/api/v1/system-prompts/{promptId}')
  Future<SystemPrompt> updatePrompt(
    @Path('promptId') int promptId,
    @Body() SystemPromptUpdate update,
  );

  @POST('/api/v1/system-prompts/{promptId}/activate')
  Future<SystemPrompt> activatePrompt(@Path('promptId') int promptId);

  // =========================================================================
  // Version Control Endpoints
  // =========================================================================

  @GET('/api/v1/system-prompts/{promptId}/versions')
  Future<List<PromptVersion>> listVersions(@Path('promptId') int promptId);

  @POST('/api/v1/system-prompts/{promptId}/rollback/{version}')
  Future<SystemPrompt> rollbackVersion(
    @Path('promptId') int promptId,
    @Path('version') int version,
  );

  // =========================================================================
  // Preview Endpoint
  // =========================================================================

  @GET('/api/v1/system-prompts/{promptId}/preview')
  Future<PromptPreview> previewPrompt(
    @Path('promptId') int promptId, {
    @Query('include_tools') bool includeTools = true,
  });
}
