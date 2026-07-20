import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { IdempotencyKey } from '../../common/decorators/idempotency-key.decorator';
import { RequestId } from '../../common/decorators/request-id.decorator';
import { InfrastructureException } from '../../common/exceptions/infrastructure.exception';
import type { AuthenticatedPrincipal } from '../../common/types/authenticated-principal';
import { CreateReadingDto } from './dto/create-reading.dto';
import { ListReadingsQueryDto } from './dto/list-readings.query.dto';
import { ReadingsService, type ReadingListPage, type ReadingResponse } from './readings.service';

/** Sprint 04: every route requires the authenticated principal. */
@ApiTags('readings')
@ApiBearerAuth()
@Controller('readings')
export class ReadingsController {
  constructor(private readonly readings: ReadingsService) {}

  @Post()
  create(
    @Body() dto: CreateReadingDto,
    @RequestId() requestId: string,
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
    @IdempotencyKey() idempotencyKey: string | null,
  ): Promise<ReadingResponse> {
    return this.readings.create(
      dto,
      requestId === 'unknown' ? null : requestId,
      this.required(principal),
      idempotencyKey,
    );
  }

  /** Newest-first history with an opaque cursor, scoped to the caller. */
  @Get()
  list(
    @Query() query: ListReadingsQueryDto,
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
  ): Promise<ReadingListPage> {
    return this.readings.list(query, this.required(principal));
  }

  /** One reading — history detail and deep links; only the caller's own. */
  @Get(':id')
  getById(
    @Param('id') id: string,
    @CurrentUser() principal: AuthenticatedPrincipal | undefined,
  ): Promise<ReadingResponse> {
    return this.readings.getById(id, this.required(principal));
  }

  private required(principal: AuthenticatedPrincipal | undefined): AuthenticatedPrincipal {
    if (!principal) {
      // The global guard guarantees a principal here; this is defense in depth.
      throw new InfrastructureException('principal missing on a guarded route', false);
    }
    return principal;
  }
}
