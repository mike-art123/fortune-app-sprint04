import { Body, Controller, Get, HttpCode, HttpStatus, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import { CompleteOnboardingDto, UpdateProfileDto } from './dto/profile.dto';
import { UsersService, type ProfileView } from './users.service';

/**
 * Profile + first-run onboarding (scope §16). All routes are authenticated;
 * the backend is the single source of truth for onboarding state, so a new
 * device or cleared cache can never re-trigger onboarding once completed.
 */
@ApiTags('profile')
@ApiBearerAuth()
@Controller('profile')
export class ProfileController {
  constructor(private readonly users: UsersService) {}

  @Get()
  profile(@CurrentUser() principal: AuthenticatedPrincipal | undefined): Promise<ProfileView> {
    return this.users.getProfile(this.requireUser(principal));
  }

  @Get('onboarding-status')
  async onboardingStatus(
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
  ): Promise<{ onboardingCompleted: boolean }> {
    const profile = await this.users.getProfile(this.requireUser(principal));
    return { onboardingCompleted: profile.onboardingCompleted };
  }

  /** Idempotent: a repeated submit returns the stored profile untouched. */
  @Post('onboarding')
  @HttpCode(HttpStatus.OK)
  completeOnboarding(
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
    @Body() dto: CompleteOnboardingDto,
  ): Promise<ProfileView> {
    return this.users.completeOnboarding(this.requireUser(principal), dto);
  }

  @Patch()
  update(
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
    @Body() dto: UpdateProfileDto,
  ): Promise<ProfileView> {
    return this.users.updateProfile(this.requireUser(principal), dto);
  }

  private requireUser(principal: AuthenticatedPrincipal | undefined): string {
    if (!principal) {
      throw new InfrastructureException('principal missing on a guarded route', false);
    }
    return principal.userId;
  }
}
