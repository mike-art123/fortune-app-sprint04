import { Module } from '@nestjs/common';
import { UsersService } from './users.service';

/** User lifecycle (Sprint 04 / doc 53). */
@Module({
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
