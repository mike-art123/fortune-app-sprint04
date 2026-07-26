import { Module } from '@nestjs/common';
import { ProfileController } from './profile.controller';
import { UsersService } from './users.service';

/** User lifecycle (Sprint 04 / doc 53) + profile onboarding (scope §16). */
@Module({
  controllers: [ProfileController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
