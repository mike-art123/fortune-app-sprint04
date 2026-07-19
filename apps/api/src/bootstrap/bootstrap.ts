import { AppConfig } from '../config/app.config';
import { AppLoggerService } from '../infrastructure/logging/app-logger.service';
import { configureApplication, createApplication } from './app-factory';
import { registerShutdown } from './shutdown';

export async function bootstrap(): Promise<void> {
  const app = configureApplication(await createApplication());
  const config = app.get(AppConfig);
  const logger = app.get(AppLoggerService);

  registerShutdown(app);
  await app.listen(config.port, config.host);

  // Startup metadata only — never secrets (doc 52 §8).
  logger.info('api_started', {
    name: config.appName,
    env: config.nodeEnv,
    port: config.port,
    prefix: `${config.apiPrefix}/v${config.apiVersion}`,
  });
}
