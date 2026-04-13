#!/usr/bin/env python3
"""Legacy compatibility entrypoint for older Sapphire launch paths."""

from sani import run


if __name__ == "__main__":
    raise SystemExit(run())
