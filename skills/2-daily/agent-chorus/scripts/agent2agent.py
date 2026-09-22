#!/usr/bin/env python3
"""DEPRECATED: agent2agent.py was renamed agent_chorus.py (AgentChorus Gen 2, issue #193 Phase 0).

This shim delegates to the renamed CLI and will be removed after one release.
Environment variables (AGENT2AGENT_HOME etc.), the Agent2Agent-Transcripts store
directory, and existing discussion files are unchanged — only the skill and CLI
names moved.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
print("agent2agent.py: deprecated — use agent_chorus.py (AgentChorus); delegating", file=sys.stderr)
import agent_chorus  # noqa: E402
sys.exit(agent_chorus.main())
