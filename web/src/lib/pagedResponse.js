/** Unwraps API list responses — legacy array or `{ items, hasNextPage, totalCount }`. */
export function unwrapPagedList(data) {
  if (Array.isArray(data)) return data;
  if (data && Array.isArray(data.items)) return data.items;
  return [];
}

export function pagedMeta(data) {
  if (!data || Array.isArray(data)) {
    return { hasNextPage: false, totalCount: Array.isArray(data) ? data.length : 0, page: 1, limit: null };
  }
  return {
    hasNextPage: Boolean(data.hasNextPage),
    totalCount: data.totalCount ?? data.items?.length ?? 0,
    page: data.page ?? 1,
    limit: data.limit ?? null,
  };
}
