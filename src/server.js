require("dotenv").config();

const appInsights = require("applicationinsights");
const express = require("express");
const helmet = require("helmet");
const path = require("path");
const { createQuoteRouter } = require("./routes/quoteRoutes");
const { getRandomQuote, checkReadiness } = require("./db/sqlClient");

if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  appInsights
    .setup(process.env.APPLICATIONINSIGHTS_CONNECTION_STRING)
    .setAutoCollectRequests(true)
    .setAutoCollectDependencies(true)
    .setAutoCollectExceptions(true)
    .setAutoDependencyCorrelation(true)
    .setSendLiveMetrics(false)
    .start();

  const client = appInsights.defaultClient;
  client.config.samplingPercentage = 25;
}

const app = express();

app.use(helmet());
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));
app.use(createQuoteRouter({ getRandomQuote, checkReadiness }));

const port = Number(process.env.PORT || 8080);

if (require.main === module) {
  app.listen(port, () => {
    process.stdout.write(`Server listening on port ${port}\n`);
  });
}

module.exports = app;