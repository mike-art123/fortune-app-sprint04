import type { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppConfig } from '../config/app.config';
import { SwaggerConfig } from '../config/swagger.config';

/** Swagger setup (doc 52 §25). Production visibility is configurable. */
export function setupOpenApi(app: INestApplication): void {
  const swagger = app.get(SwaggerConfig);
  const appConfig = app.get(AppConfig);
  if (!swagger.enabled) return;

  const config = new DocumentBuilder()
    .setTitle('Fortune API')
    .setDescription('Backend foundation for the Fortune App (docs 33/52).')
    .setVersion(`v${appConfig.apiVersion}`)
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup(`${appConfig.apiPrefix}/${swagger.path}`, app, document);
}
