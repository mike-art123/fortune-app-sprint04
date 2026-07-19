module.exports = {
  root: true,
  ...require('@fortune/lint-rules/eslint-base.cjs'),
  parserOptions: { project: 'tsconfig.json', sourceType: 'module' },
  ignorePatterns: ['dist/', 'node_modules/', '.eslintrc.cjs'],
};
