# Code style

- No extra config knobs, wrapper helpers, classes, or plugin hooks. A function called once can stay inline.
- Ruff settings are in `pyproject.toml`; `ruff check` and `ruff format --check` must pass.
