from __future__ import annotations

from pydantic import SecretStr

from openhands.core.config.openhands_config import OpenHandsConfig
from openhands.storage.data_models.settings import Settings
from openhands.utils.utils import setup_llm_config


def _build_settings(model: str, base_url: str) -> Settings:
    return Settings(
        llm_model=model,
        llm_base_url=base_url,
        llm_api_key=SecretStr('test-key'),
    )


def test_setup_llm_config_normalizes_registry_ollama_model_and_disables_native_tools():
    config = OpenHandsConfig()
    settings = _build_settings(
        'registry.ollama.ai/library/deepseek-r1:14b',
        'http://localhost:11434',
    )

    updated = setup_llm_config(config, settings)
    llm_config = updated.get_llm_config()

    assert llm_config.model == 'ollama/deepseek-r1:14b'
    assert llm_config.native_tool_calling is False


def test_setup_llm_config_disables_native_tools_for_bare_tagged_model_on_ollama_url():
    config = OpenHandsConfig()
    settings = _build_settings('deepseek-r1:14b', 'http://localhost:11434')

    updated = setup_llm_config(config, settings)
    llm_config = updated.get_llm_config()

    assert llm_config.native_tool_calling is False


def test_setup_llm_config_patches_named_llm_profiles():
    """Named profiles (e.g. [llm.deepseek-r1] in config.toml) should also be
    normalized and have native_tool_calling disabled when they are Ollama models."""
    from openhands.core.config.llm_config import LLMConfig

    named = LLMConfig(
        model='registry.ollama.ai/library/deepseek-r1:14b',
        base_url='http://localhost:11434',
    )
    config = OpenHandsConfig(llms={'llm': LLMConfig(), 'deepseek-r1': named})
    settings = _build_settings('gpt-4o', '')  # default profile uses a non-Ollama model

    updated = setup_llm_config(config, settings)

    # Default profile should be unchanged (non-Ollama)
    assert updated.get_llm_config().native_tool_calling is not False

    # Named Ollama profile should be normalized and disabled
    patched = updated.llms['deepseek-r1']
    assert patched.model == 'ollama/deepseek-r1:14b'
    assert patched.native_tool_calling is False
