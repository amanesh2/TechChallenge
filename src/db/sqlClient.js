const sql = require("mssql");
const { DefaultAzureCredential } = require("@azure/identity");

const SQL_SCOPE = "https://database.windows.net/.default";

function getBaseConfig() {
  const server = process.env.SQL_SERVER_FQDN;
  const database = process.env.SQL_DATABASE_NAME;

  if (!server || !database) {
    throw new Error("SQL_SERVER_FQDN and SQL_DATABASE_NAME must be configured.");
  }

  return {
    server,
    database,
    options: {
      encrypt: true,
      trustServerCertificate: false
    },
    pool: {
      max: 10,
      min: 1,
      idleTimeoutMillis: 30000
    },
    connectionTimeout: 15000,
    requestTimeout: 15000
  };
}

const retryableSqlErrors = new Set([40613, 40197, 40501, 49918, 49919, 49920, 10928, 10929]);

let pool;

async function createPool() {
  const credential = new DefaultAzureCredential();
  const token = await credential.getToken(SQL_SCOPE);
  if (!token || !token.token) {
    throw new Error("Unable to acquire Azure SQL access token.");
  }

  const config = {
    ...getBaseConfig(),
    authentication: {
      type: "azure-active-directory-access-token",
      options: {
        token: token.token
      }
    }
  };

  const createdPool = new sql.ConnectionPool(config);
  createdPool.on("error", () => {
    pool = undefined;
  });

  await createdPool.connect();
  return createdPool;
}

async function getPool() {
  if (!pool) {
    pool = await createPool();
  }
  return pool;
}

async function withRetry(operation, maxAttempts = 3) {
  let lastError;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      const number = error?.originalError?.info?.number || error?.number;
      const isRetryable = retryableSqlErrors.has(number);

      if (!isRetryable || attempt === maxAttempts) {
        throw error;
      }
    }
  }

  throw lastError;
}

async function getRandomQuote() {
  return withRetry(async () => {
    const activePool = await getPool();
    const result = await activePool.request().query(`
      SELECT TOP 1
        quote_text AS quote,
        author_name AS author
      FROM dbo.Quotes
      WHERE is_active = 1
      ORDER BY NEWID();
    `);

    return result.recordset[0] || null;
  });
}

async function checkReadiness() {
  return withRetry(async () => {
    const activePool = await getPool();
    await activePool.request().query("SELECT 1 AS ready;");
    return true;
  });
}

module.exports = {
  getRandomQuote,
  checkReadiness
};