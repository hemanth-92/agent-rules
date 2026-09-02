---
name: data-pipeline-bdd
description: Design, implement, test, and validate data engineering pipelines using Gherkin BDD specifications, Extract-Transform-Validate-Load (E-T-V-L) templates, schema contracts, PySpark/DuckDB, and automated test-driven iteration. Use when asked to generate production data pipelines, define ETL requirements with Given/When/Then specs, write behavior tests with behave or pytest, or prevent AI spaghetti code in data workflows.
category: data-engineering
---

# data-pipeline-bdd

## Workflow

1. **Define Requirements with Gherkin BDD**:
   - Write `.feature` files using `Given` (input sources/samples), `When` (transformation actions), `Then` (grain, PKs, metrics), and `And` (schema constraints).
   - Use explicit schema contracts (Pydantic, dataclasses, or SQL DDL) alongside Gherkin business rules to specify exact column types and constraints.

2. **Template Structure (Extract -> Transform -> Validate -> Load)**:
   - Separate concerns into distinct, testable pure functions:
     - `extract(spark/db) -> dict[str, DataFrame]`
     - `transform(input_dfs: dict[str, DataFrame]) -> DataFrame`
     - `validate(df: DataFrame) -> bool`
     - `load(df: DataFrame) -> None`
     - `run(spark/db) -> None`

3. **Performance & Spark Safety Rules**:
   - Avoid Python UDFs; use native `pyspark.sql.functions` or SQL expressions.
   - Never call eager evaluation methods (`.collect()`, `.toPandas()`, `.show()`) inside `transform()`.
   - Prevent double-scanning lazy DataFrames in `validate()`; persist intermediate results or perform single-pass data quality metrics.
   - Always specify explicit join keys and null-handling logic.

4. **Automated Test-Driven Iteration**:
   - Execute tests locally using `uv run behave` or `uv run pytest`.
   - Use DuckDB or lightweight PySpark fixtures for fast local test feedback loops.
   - Parse test errors, fix transformation logic, and re-run verification automatically.

## Diagnostics

```bash
uv run behave
uv run pytest tests/
uv run ruff check .
uv run mypy .
```

## Validation

- Gherkin feature files pass with `behave` or `pytest`.
- Output schema matches column names, data types, and primary key grain.
- `transform()` function is pure and decoupled from I/O extraction and loading.
- Pipelines run cleanly without eager evaluation memory spikes or double-scan overhead.
