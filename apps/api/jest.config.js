module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  // isolatedModules: transpile specs instead of full type-checking them.
  // Full type-checking of src is already covered by `npm run build`
  // (tsconfig.build) and `npm run lint`. Under noUncheckedIndexedAccess,
  // idiomatic test code like `token.split('.')[0]` is `string | undefined`,
  // which is safe at runtime but would fail a ts-jest type-check.
  transform: { '^.+\\.ts$': ['ts-jest', { isolatedModules: true }] },
  collectCoverageFrom: ['**/*.(t|j)s'],
  coverageDirectory: '../coverage',
  testEnvironment: 'node',
};
