import { HttpStatus, Injectable, PipeTransform } from '@nestjs/common';
import { DomainException } from '../exceptions/domain.exception';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/** Validates route ids without leaking parser internals. */
@Injectable()
export class ParseUuidPipe implements PipeTransform<string, string> {
  transform(value: string): string {
    if (!UUID_RE.test(value)) {
      throw new DomainException('VALIDATION_FAILED', 'شناسه‌ی نامعتبر است.', {
        status: HttpStatus.BAD_REQUEST,
      });
    }
    return value;
  }
}
