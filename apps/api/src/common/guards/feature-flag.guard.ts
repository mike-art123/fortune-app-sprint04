import { CanActivate, ExecutionContext, HttpStatus, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { FEATURE_FLAG_KEY } from '../constants/metadata.constants';
import { DomainException } from '../exceptions/domain.exception';
import { FeatureFlagsService } from '../../infrastructure/feature-flags/feature-flags.service';

/** Gates a route behind a server-side flag (doc 52 §36). */
@Injectable()
export class FeatureFlagGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly flags: FeatureFlagsService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const flagKey = this.reflector.getAllAndOverride<string | undefined>(FEATURE_FLAG_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!flagKey) return true;
    if (await this.flags.isEnabled(flagKey)) return true;
    throw new DomainException('NOT_FOUND', 'موردی که دنبالش بودی پیدا نشد.', {
      status: HttpStatus.NOT_FOUND,
    });
  }
}
