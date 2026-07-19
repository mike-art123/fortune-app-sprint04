import { ValidationPipe, VersioningType, type INestApplication } from '@nestjs/common';
import { NestFactory, Reflector } from '@nestjs/core';
import helmet from 'helmet';
import compression from 'compression';
import { json, urlencoded } from 'express';
import { Logger } from 'nestjs-pino';
import { AppModule } from '../app.module';
import { AppConfig } from '../config/app.config';
import { GlobalExceptionFilter } from '../common/filters/global-exception.filter';
import { LoggingInterceptor } from '../common/interceptors/logging.interceptor';
import { RequestContextInterceptor } from '../common/interceptors/request-context.interceptor';
import { ResponseMetadataInterceptor } from '../common/interceptors/response-metadata.interceptor';
import { TimeoutInterceptor } from '../common/interceptors/timeout.interceptor';
import { AppLoggerService } from '../infrastructure/logging/app-logger.service';
import { setupOpenApi } from '../docs/openapi.setup';

/**
 * Creates and configures the application (doc 52 §8). Shared by main.ts and
 * e2e tests so both run the identical pipeline.
 */
export async function createApplication(): Promise<INestApplication> {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.useLogger(app.get(Logger));
  return app;
}

export function configureApplication(app: INestApplication): INestApplication {
  const appConfig = app.get(AppConfig);
  const logger = app.get(AppLoggerService);

  app.enableShutdownHooks();
  app.use(helmet());
  app.use(compression());
  app.use(json({ limit: '1mb' }));
  app.use(urlencoded({ extended: true, limit: '1mb' }));

  const origins = appConfig.corsAllowedOrigins;
  app.enableCors({
    origin: appConfig.isProduction ? origins : origins.length > 0 ? origins : true,
    credentials: true,
  });

  app.setGlobalPrefix(appConfig.apiPrefix);
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: appConfig.apiVersion });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: false },
    }),
  );

  // Order matters: context first, then envelope/timeout/logging.
  app.useGlobalInterceptors(
    new RequestContextInterceptor(),
    new ResponseMetadataInterceptor(),
    new TimeoutInterceptor(appConfig),
    new LoggingInterceptor(logger),
  );
  app.useGlobalFilters(new GlobalExceptionFilter(logger));

  // Reflector is resolved to ensure guard metadata works in all contexts.
  app.get(Reflector);

  setupOpenApi(app);
  return app;
}
