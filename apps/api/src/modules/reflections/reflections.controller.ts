import { Body, Controller, Delete, Get, Param, Put, Query } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import {
  ListReflectionsQueryDto,
  ReflectionPromptQueryDto,
  SaveReflectionDto,
} from './dto/reflection.dto';
import type { Feeling, ReflectionPrompt } from './reflection-feelings';
import {
  ReflectionsService,
  type ReflectionPage,
  type ReflectionView,
} from './reflections.service';

/**
 * The reflection journal (scope §8). Every route is scoped to the caller: there
 * is no shape of request here that can reach somebody else's diary.
 */
@ApiTags('reflections')
@ApiBearerAuth()
@Controller('reflections')
export class ReflectionsController {
  constructor(private readonly reflections: ReflectionsService) {}

  @Get()
  list(
    @Query() query: ListReflectionsQueryDto,
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
  ): Promise<ReflectionPage> {
    const userId = this.required(principal).userId;
    return this.reflections.list(userId, query.limit ?? 20, query.cursor);
  }

  /** The written line for a feeling. No note is sent, so none can leak. */
  @Get('prompt')
  @Throttle({ default: { limit: 30, ttl: 60_000 } })
  prompt(
    @Query() query: ReflectionPromptQueryDto,
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
  ): Promise<ReflectionPrompt> {
    this.required(principal);
    return this.reflections.prompt(query.feeling as Feeling);
  }

  @Get('reading/:readingId')
  forReading(
    @Param('readingId') readingId: string,
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
  ): Promise<ReflectionView | null> {
    return this.reflections.forReading(this.required(principal).userId, readingId);
  }

  /**
   * PUT, not POST: coming back to the same reading edits what is already there
   * rather than stacking a second copy of the same thought.
   */
  @Put()
  @Throttle({ default: { limit: 60, ttl: 60_000 } })
  save(
    @Body() dto: SaveReflectionDto,
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
  ): Promise<ReflectionView> {
    return this.reflections.save(this.required(principal).userId, {
      readingId: dto.readingId ?? null,
      feeling: dto.feeling as Feeling,
      note: dto.note,
    });
  }

  /**
   * Answers with the id it removed: the response envelope always carries a
   * body, and «رفت» is easier to show than an empty 204.
   */
  @Delete(':id')
  remove(
    @Param('id') id: string,
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
  ): Promise<{ id: string }> {
    return this.reflections.remove(this.required(principal).userId, id);
  }

  private required(principal: AuthenticatedPrincipal | undefined): AuthenticatedPrincipal {
    if (!principal) {
      // The global guard guarantees a principal here; this is defense in depth.
      throw new InfrastructureException('principal missing on a guarded route', false);
    }
    return principal;
  }
}
