const express = require("express");

function createQuoteRouter({ getRandomQuote, checkReadiness }) {
  const router = express.Router();

  router.get("/health", (_req, res) => {
    res.status(200).json({ status: "ok" });
  });

  router.get("/health/ready", async (_req, res) => {
    try {
      await checkReadiness();
      res.status(200).json({ status: "ready" });
    } catch (_error) {
      res.status(503).json({ status: "not-ready" });
    }
  });

  router.get("/api/quote", async (_req, res) => {
    try {
      const quote = await getRandomQuote();

      if (!quote) {
        return res.status(404).json({ error: "No quote found" });
      }

      return res.status(200).json(quote);
    } catch (_error) {
      return res.status(500).json({ error: "Failed to retrieve quote" });
    }
  });

  router.get("/", async (_req, res) => {
    try {
      const quote = await getRandomQuote();
      if (!quote) {
        return res.status(404).send("<h1>No quote found</h1>");
      }

      return res.status(200).send(`
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>Quote of the Day</title>
          <link rel="stylesheet" href="/styles.css" />
        </head>
        <body>
          <main class="card">
            <h1>Quote of the Day</h1>
            <blockquote>${quote.quote}</blockquote>
            <p class="author">- ${quote.author}</p>
            <a href="/" class="refresh">Show another quote</a>
          </main>
        </body>
        </html>
      `);
    } catch (_error) {
      return res.status(500).send("<h1>Unexpected server error</h1>");
    }
  });

  return router;
}

module.exports = {
  createQuoteRouter
};