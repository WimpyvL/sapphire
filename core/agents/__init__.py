from .manager import AgentManager
from .base_worker import BaseWorker

# Module-level singleton — created once in sani.py, accessible to plugins during scan
agent_manager = None

__all__ = ['AgentManager', 'BaseWorker', 'agent_manager']
