function createResponse() {
  return {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    }
  };
}

async function withOverrides(overrides, run) {
  const originals = overrides.map(([target, property]) => target[property]);

  try {
    overrides.forEach(([target, property, replacement]) => {
      target[property] = replacement;
    });
    await run();
  } finally {
    overrides.forEach(([target, property], index) => {
      target[property] = originals[index];
    });
  }
}

async function withMutedConsoleError(run) {
  const originalConsoleError = console.error;
  console.error = () => {};

  try {
    await run();
  } finally {
    console.error = originalConsoleError;
  }
}

module.exports = { createResponse, withOverrides, withMutedConsoleError };
