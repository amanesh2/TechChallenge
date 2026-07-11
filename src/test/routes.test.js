const test = require("node:test");
const assert = require("node:assert/strict");
const express = require("express");
const { createQuoteRouter } = require("../routes/quoteRoutes");

function startServer(overrides = {}) {
  const app = express();
  app.use(
    createQuoteRouter({
      getRandomQuote: async () => ({ quote: "Stay hungry, stay foolish.", author: "Steve Jobs" }),
      checkReadiness: async () => true,
      ...overrides
    })
  );

  return new Promise((resolve) => {
    const server = app.listen(0, () => {
      const { port } = server.address();
      resolve({ server, port });
    });
  });
}

test("GET /health returns ok", async () => {
  const { server, port } = await startServer();
  const response = await fetch(`http://127.0.0.1:${port}/health`);
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.status, "ok");
  server.close();
});

test("GET /health/ready returns ready", async () => {
  const { server, port } = await startServer();
  const response = await fetch(`http://127.0.0.1:${port}/health/ready`);
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.status, "ready");
  server.close();
});

test("GET /api/quote returns quote payload", async () => {
  const { server, port } = await startServer();
  const response = await fetch(`http://127.0.0.1:${port}/api/quote`);
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.author, "Steve Jobs");
  server.close();
});

test("GET /health/ready returns 503 on DB failure", async () => {
  const { server, port } = await startServer({
    checkReadiness: async () => {
      throw new Error("db down");
    }
  });

  const response = await fetch(`http://127.0.0.1:${port}/health/ready`);
  assert.equal(response.status, 503);
  server.close();
});