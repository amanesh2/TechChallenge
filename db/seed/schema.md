# Quotes Schema

## Table

`dbo.Quotes`

## Columns

- `id` (INT IDENTITY, primary key)
- `quote_text` (NVARCHAR(1000), required)
- `author_name` (NVARCHAR(255), required)
- `category` (NVARCHAR(100), nullable)
- `source` (NVARCHAR(255), nullable)
- `is_active` (BIT, default `1`)
- `created_at` (DATETIME2, default UTC timestamp)

## Constraints

- Unique index on (`quote_text`, `author_name`) to support idempotent seeding.

## Access Model

- Runtime app identity: read-only (`db_datareader`)
- Seeder identity: write rights (`db_datawriter`) for seed and curation operations
