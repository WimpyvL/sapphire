__version__ = "0.3.0"
__all__ = [
    "LLMChat",
    "ConversationHistory",
]


def __getattr__(name):
    if name == "LLMChat":
        from .chat import LLMChat
        return LLMChat
    if name == "ConversationHistory":
        from .history import ConversationHistory
        return ConversationHistory
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
