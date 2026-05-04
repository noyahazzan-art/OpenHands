import os
from copy import deepcopy
from urllib.parse import urlparse

from openhands.core.config.openhands_config import OpenHandsConfig
from openhands.llm.llm_registry import LLMRegistry
from openhands.server.services.conversation_stats import ConversationStats
from openhands.storage import get_file_store
from openhands.storage.data_models.settings import Settings
from openhands.utils.environment import get_effective_llm_base_url


def _normalize_ollama_model_name(model: str) -> str:
    if not model:
        return model
    if 'registry.ollama.ai/library/' in model:
        return 'ollama/' + model.split('/library/', 1)[1]
    if model.startswith('library/'):
        return 'ollama/' + model[len('library/') :]
    if model.startswith('ollama/'):
        tail = model[len('ollama/') :]
        if 'registry.ollama.ai/library/' in tail:
            return 'ollama/' + tail.split('/library/', 1)[1]
        if tail.startswith('library/'):
            return 'ollama/' + tail[len('library/') :]
    return model


def _is_probably_ollama_model(model: str, base_url: str | None) -> bool:
    raw = (model or '').strip().lower()
    if not raw:
        return False
    if (
        raw.startswith('ollama/')
        or raw.startswith('library/')
        or 'registry.ollama.ai/' in raw
    ):
        return True
    if not base_url:
        return False
    parsed = urlparse(base_url)
    host = (parsed.hostname or '').lower()
    if parsed.port == 11434 or 'ollama' in host:
        return True
    # Bare tagged models (e.g. deepseek-r1:14b) behind reverse proxies.
    if '/' not in raw and ':' in raw:
        return True
    return False


def setup_llm_config(config: OpenHandsConfig, settings: Settings) -> OpenHandsConfig:
    # Copying this means that when we update variables they are not applied to the shared global configuration!
    config = deepcopy(config)

    llm_config = config.get_llm_config()
    llm_config.model = _normalize_ollama_model_name(settings.llm_model or '')
    llm_config.api_key = settings.llm_api_key
    env_base_url = os.environ.get('LLM_BASE_URL')
    settings_base_url = settings.llm_base_url

    # Use env_base_url if available, otherwise fall back to settings_base_url
    base_url_to_use = (
        env_base_url if env_base_url not in (None, '') else settings_base_url
    )

    llm_config.base_url = get_effective_llm_base_url(
        llm_config.model,
        base_url_to_use,
        llm_config.custom_llm_provider,
    )
    if _is_probably_ollama_model(llm_config.model, llm_config.base_url):
        llm_config.native_tool_calling = False

    config.set_llm_config(llm_config)

    # Also normalize and patch every named LLM profile so that profiles
    # defined in config.toml (e.g. [llm.deepseek-r1]) are protected even
    # when get_llm_config_from_agent() returns a profile other than 'llm'.
    for profile_name, named_config in config.llms.items():
        if profile_name == 'llm':
            continue  # already handled above
        normalized = _normalize_ollama_model_name(named_config.model or '')
        if normalized != named_config.model:
            named_config.model = normalized
        if _is_probably_ollama_model(named_config.model, named_config.base_url):
            named_config.native_tool_calling = False

    return config


def create_registry_and_conversation_stats(
    config: OpenHandsConfig,
    sid: str,
    user_id: str | None,
    user_settings: Settings | None = None,
) -> tuple[LLMRegistry, ConversationStats, OpenHandsConfig]:
    user_config = config
    if user_settings:
        user_config = setup_llm_config(config, user_settings)

    agent_cls = user_settings.agent if user_settings else None
    llm_registry = LLMRegistry(user_config, agent_cls)
    file_store = get_file_store(
        file_store_type=config.file_store,
        file_store_path=config.file_store_path,
        file_store_web_hook_url=config.file_store_web_hook_url,
        file_store_web_hook_headers=config.file_store_web_hook_headers,
        file_store_web_hook_batch=config.file_store_web_hook_batch,
    )
    conversation_stats = ConversationStats(file_store, sid, user_id)
    llm_registry.subscribe(conversation_stats.register_llm)
    return llm_registry, conversation_stats, user_config
