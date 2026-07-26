import { Module } from '@nestjs/common';
import { ReflectionsController } from './reflections.controller';
import { ReflectionsService } from './reflections.service';

/**
 * Reflection journal (scope §8). It owns nothing but its own table, and that
 * table is the most private one in the database — nothing else reads it.
 */
@Module({
  controllers: [ReflectionsController],
  providers: [ReflectionsService],
})
export class ReflectionsModule {}
