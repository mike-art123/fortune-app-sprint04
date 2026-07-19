import { PrismaClient } from '@prisma/client';

/**
 * Idempotent development seed (doc 52 §42). No fake users, balances, or
 * entitlements — only infrastructure defaults, clearly non-production.
 */
const prisma = new PrismaClient();

async function main(): Promise<void> {
  await prisma.systemSetting.upsert({
    where: { key: 'seed.environment' },
    create: { key: 'seed.environment', value: 'development' },
    update: { value: 'development' },
  });

  await prisma.featureFlag.upsert({
    where: { key: 'system.maintenance-banner' },
    create: { key: 'system.maintenance-banner', enabled: false, note: 'dev default' },
    update: {},
  });
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
