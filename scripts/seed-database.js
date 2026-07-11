#!/usr/bin/env node
const fs = require("node:fs");
const path = require("node:path");
const sql = require("mssql");
const { DefaultAzureCredential } = require("@azure/identity");

const SQL_SCOPE = "https://database.windows.net/.default";

function readSeedData() {
  const seedPath = path.resolve(__dirname, "..", "db", "seed", "quotes-seed-data.json");
  return JSON.parse(fs.readFileSync(seedPath, "utf8"));
}

async function getPool() {
  const server = process.env.SQL_SERVER_FQDN;
  const database = process.env.SQL_DATABASE_NAME;
  if (!server || !database) {
    throw new Error("SQL_SERVER_FQDN and SQL_DATABASE_NAME are required.");
  }

  const credential = new DefaultAzureCredential();
  const token = await credential.getToken(SQL_SCOPE);

  const config = {
    server,
    database,
    options: {
      encrypt: true,
      trustServerCertificate: false
    },
    authentication: {
      type: "azure-active-directory-access-token",
      options: {
        token: token.token
      }
    }
  };

  const pool = new sql.ConnectionPool(config);
  await pool.connect();
  return pool;
}

async function ensureSchema(pool) {
  await pool.request().query(`
    IF OBJECT_ID('dbo.Quotes', 'U') IS NULL
    BEGIN
      CREATE TABLE dbo.Quotes (
        id INT IDENTITY(1,1) PRIMARY KEY,
        quote_text NVARCHAR(1000) NOT NULL,
        author_name NVARCHAR(255) NOT NULL,
        category NVARCHAR(100) NULL,
        source NVARCHAR(255) NULL,
        is_active BIT NOT NULL CONSTRAINT DF_Quotes_IsActive DEFAULT(1),
        created_at DATETIME2 NOT NULL CONSTRAINT DF_Quotes_CreatedAt DEFAULT(SYSUTCDATETIME())
      );

      CREATE UNIQUE INDEX UX_Quotes_Text_Author
      ON dbo.Quotes(quote_text, author_name);
    END;
  `);
}

async function seedQuotes(pool, quotes) {
  for (const item of quotes) {
    const request = pool.request();
    request.input("quote", sql.NVarChar(1000), item.quote);
    request.input("author", sql.NVarChar(255), item.author);

    await request.query(`
      MERGE dbo.Quotes AS target
      USING (SELECT @quote AS quote_text, @author AS author_name) AS source
      ON target.quote_text = source.quote_text
        AND target.author_name = source.author_name
      WHEN MATCHED THEN
        UPDATE SET is_active = 1
      WHEN NOT MATCHED BY TARGET THEN
        INSERT (quote_text, author_name, is_active)
        VALUES (source.quote_text, source.author_name, 1);
    `);
  }
}

async function run() {
  const quotes = readSeedData();
  const pool = await getPool();

  try {
    await ensureSchema(pool);
    await seedQuotes(pool, quotes);
    process.stdout.write(`Seeded ${quotes.length} quotes successfully.\n`);
  } finally {
    await pool.close();
  }
}

run().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
});