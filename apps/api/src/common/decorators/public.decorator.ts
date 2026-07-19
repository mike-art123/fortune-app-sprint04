import { SetMetadata } from '@nestjs/common';
import { IS_PUBLIC_KEY } from '../constants/metadata.constants';

/** Marks a route as public — the auth guard skips it (doc 52 §28). */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
