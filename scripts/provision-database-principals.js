#!/usr/bin/env node
const sql = require("mssql");
const { DefaultAzureCredential } = require("@azure/identity");

const SQL_SCOPE = "https://database.windows.net/.default";

async function main() {
  const server = process.env.SQL_SERVER_FQDN;
  const database = process.env.SQL_DATABASE_NAME;
  const appIdentityName = process.env.APP_UAMI_NAME;
  const seederIdentityName = process.env.SEEDER_UAMI_NAME;

  if (!server || !database || !appIdentityName || !seederIdentityName) {
    throw new Error("SQL_SERVER_FQDN, SQL_DATABASE_NAME, APP_UAMI_NAME, and SEEDER_UAMI_NAME are required.");
  }

  const credential = new DefaultAzureCredential();
  const token = await credential.getToken(SQL_SCOPE);

  const pool = new sql.ConnectionPool({
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
  });

  await pool.connect();

  try {
    await pool.request().batch(`
      IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '${appIdentityName}')
      BEGIN
        CREATE USER [${appIdentityName}] FROM EXTERNAL PROVIDER;
      END;

      IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '${seederIdentityName}')
      BEGIN
        CREATE USER [${seederIdentityName}] FROM EXTERNAL PROVIDER;
      END;

      ALTER ROLE db_datareader ADD MEMBER [${appIdentityName}];
      ALTER ROLE db_datareader ADD MEMBER [${seederIdentityName}];
      ALTER ROLE db_datawriter ADD MEMBER [${seederIdentityName}];
    `);

    process.stdout.write("Database principals provisioned successfully.\n");
  } finally {
    await pool.close();
  }
}

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
});