"""
Shared pytest configuration.

Automatically applies the `unit` marker to all tests in files ending with
`_unit.py` (pure-logic tests, no database required) and the `integration`
marker to all other test files (require a seeded PostgreSQL database via
DATABASE_URL).

This lets contributors run:
    pytest -m unit          # fast, no DB needed
    pytest -m integration   # full API/DB tests
    pytest                  # everything
"""

import pytest


def pytest_collection_modifyitems(config, items):
    for item in items:
        if item.fspath.basename.endswith("_unit.py"):
            item.add_marker(pytest.mark.unit)
        else:
            item.add_marker(pytest.mark.integration)
