module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    // In-update para suportahan ang optional chaining (?.)
    // at modern JS syntax.
    "ecmaVersion": 2020,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", {"allowTemplateLiterals": true}],
    "linebreak-style": "off", // Pinatay ang CRLF error para sa Windows
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
