export class CursorPaginationMetaDto {
  nextCursor: string | null = null;
}

export interface PaginatedResponse<T> {
  items: T[];
  nextCursor: string | null;
}
