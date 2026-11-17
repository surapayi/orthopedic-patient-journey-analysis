# 05 Data Quality

This folder tests the data model with made-up data and SQL checks.

I have not worked in a clinic. Everything here is built from public sources and my own assumptions. All data is synthetic. Nothing comes from a real clinic or a real patient.

## What is in this folder

| File | What it is | Status |
|---|---|---|
| `sample-data-plan.md` | The scenarios and planted errors I chose, and my assumptions | Draft |
| `sql/01-create-tables.sql` | Builds the 10 tables in SQLite from the data dictionary | Planned |
| `sql/02-sample-data.sql` | Loads the made-up rows | Planned |
| `sql/03-dq-checks.sql` | SQL checks that look for problems in the data | Planned |
| `data-quality-checks.md` | Each check, the rule, the result, and what I learned | Planned |

## How the pieces fit

1. The [data dictionary](../04-data-dictionary.md) says what each column means.
2. The sample data plan says which rows to make, and why.
3. The SQL files build the tables and load the rows.
4. The checks run against the rows. Normal rows should pass. Planted errors should be caught.

## Run order (once the SQL files exist)

1. Open a new database in DB Browser for SQLite.
2. Run `01-create-tables.sql`.
3. Run `02-sample-data.sql`.
4. Run `03-dq-checks.sql`.

## Related files

- [Data dictionary](../04-data-dictionary.md)
- [ERD](../03-data-model/)
- [Glossary](../glossary.md)
