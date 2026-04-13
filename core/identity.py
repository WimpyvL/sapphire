"""Centralized product identity and legacy-compat helpers."""
from __future__ import annotations

import os
import sys
from pathlib import Path

PRODUCT_NAME = "Sani"
LEGACY_PRODUCT_NAME = "Sapphire"

PRODUCT_SLUG = "sani"
LEGACY_PRODUCT_SLUG = "sapphire"

DEFAULT_PERSONA = PRODUCT_SLUG
LEGACY_DEFAULT_PERSONA = LEGACY_PRODUCT_SLUG

DEFAULT_PROMPT = PRODUCT_SLUG
LEGACY_DEFAULT_PROMPT = LEGACY_PRODUCT_SLUG

SESSION_COOKIE = "sani_session"
LEGACY_SESSION_COOKIE = "sapphire_session"

HISTORY_DB_NAME = "sani_history.db"
LEGACY_HISTORY_DB_NAME = "sapphire_history.db"

BACKUP_PREFIX = PRODUCT_SLUG
LEGACY_BACKUP_PREFIX = LEGACY_PRODUCT_SLUG

THEME_STORAGE_KEY = "sani-theme"
LEGACY_THEME_STORAGE_KEY = "sapphire-theme"

WAKEWORD_MODEL = "hey_sani"
LEGACY_WAKEWORD_MODEL = "hey_sapphire"

PLUGIN_VERIFY_USER_AGENT = "Sani-PluginVerify/1.0"


def env_get(*names: str, default: str | None = None) -> str | None:
    """Return the first non-empty environment value from the provided names."""
    for name in names:
        value = os.environ.get(name)
        if value not in (None, ""):
            return value
    return default


def env_flag(*names: str) -> bool:
    """True if any alias env var is present and truthy."""
    value = env_get(*names)
    if value is None:
        return False
    return str(value).strip().lower() in ("1", "true", "yes", "on")


def get_product_name() -> str:
    return PRODUCT_NAME


def get_prompt_alias(name: str | None) -> str | None:
    """Map legacy default prompt identifiers to the canonical Sani prompt."""
    if not name:
        return name
    if name == LEGACY_DEFAULT_PROMPT:
        return DEFAULT_PROMPT
    return name


def get_persona_alias(name: str | None) -> str | None:
    """Map legacy default persona identifiers to the canonical Sani persona."""
    if not name:
        return name
    if name == LEGACY_DEFAULT_PERSONA:
        return DEFAULT_PERSONA
    return name


def get_config_dir_candidates() -> tuple[Path, Path]:
    """Return (new_dir, legacy_dir) for the current platform."""
    if sys.platform == "win32":
        base = os.environ.get("APPDATA")
        if base:
            root = Path(base)
        else:
            root = Path.home() / "AppData" / "Roaming"
        return root / PRODUCT_NAME, root / LEGACY_PRODUCT_NAME

    if sys.platform == "darwin":
        root = Path.home() / "Library" / "Application Support"
        return root / PRODUCT_NAME, root / LEGACY_PRODUCT_NAME

    xdg_config = os.environ.get("XDG_CONFIG_HOME")
    if xdg_config:
        root = Path(xdg_config)
    else:
        root = Path.home() / ".config"
    return root / PRODUCT_SLUG, root / LEGACY_PRODUCT_SLUG


def select_config_dir() -> Path:
    """Use new config dir for fresh installs, legacy dir for existing installs."""
    new_dir, legacy_dir = get_config_dir_candidates()
    if legacy_dir.exists() and not new_dir.exists():
        return legacy_dir
    return new_dir


def history_db_path(history_dir: Path) -> Path:
    """Use new DB name unless a legacy DB already exists in this history directory."""
    legacy = history_dir / LEGACY_HISTORY_DB_NAME
    current = history_dir / HISTORY_DB_NAME
    if legacy.exists() and not current.exists():
        return legacy
    return current


def backup_prefixes() -> tuple[str, str]:
    return BACKUP_PREFIX, LEGACY_BACKUP_PREFIX


def github_repo() -> str:
    """Centralized repo target; allows an unreleased Sani repo to be wired later."""
    return (
        env_get("SANI_GITHUB_REPO", "SAPPHIRE_GITHUB_REPO")
        or "ddxfish/sapphire"
    )
