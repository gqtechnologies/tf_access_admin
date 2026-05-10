import { computed, ref, toValue, watch, type MaybeRefOrGetter, type Ref } from 'vue'
import { useDebounceFn } from '@vueuse/core'

export type AsyncPaginatedPage<T extends { id: string }> = {
  items: T[]
  currentPage: number
  totalPages: number
}

export type AsyncPaginatedFetcher<T extends { id: string }> = (args: {
  page: number
  search: string
  perPage: number
  extraParams: Record<string, string>
}) => Promise<AsyncPaginatedPage<T>>

function mergeSeeds<T extends { id: string }>(seeds: T[], rows: T[]): T[] {
  if (!seeds.length) return rows
  const seen = new Set(rows.map((r) => r.id))
  const prefix: T[] = []
  for (const s of seeds) {
    if (s?.id && !seen.has(s.id)) {
      prefix.push(s)
      seen.add(s.id)
    }
  }
  return [...prefix, ...rows]
}

export function useAsyncPaginatedSelect<T extends { id: string }>(
  fetcher: AsyncPaginatedFetcher<T>,
  options: {
    perPage?: number
    debounceMs?: number
    extraParams?: MaybeRefOrGetter<Record<string, string>>
  } = {},
) {
  const perPage = options.perPage ?? 20
  const debounceMs = options.debounceMs ?? 300
  const extraParams = options.extraParams ?? {}

  const remoteItems = ref([]) as Ref<T[]>
  const seeds = ref([]) as Ref<T[]>
  const search = ref('')
  const debouncedSearch = ref('')
  const loading = ref(false)
  const lastLoadedPage = ref(0)
  const totalPages = ref(1)

  const debouncedCommitSearch = useDebounceFn((value: string) => {
    debouncedSearch.value = value
    void resetAndFetch()
  }, debounceMs)

  watch(search, (v) => {
    void debouncedCommitSearch(v)
  })

  const displayItems = computed(() => mergeSeeds(seeds.value, remoteItems.value))

  async function fetchPage(page: number, replace: boolean) {
    const params = {
      page,
      search: debouncedSearch.value,
      perPage,
      extraParams: { ...toValue(extraParams) },
    }
    const data = await fetcher(params)
    totalPages.value = data.totalPages
    lastLoadedPage.value = data.currentPage
    const batch = data.items
    if (replace) {
      remoteItems.value = batch
    } else {
      const seen = new Set(remoteItems.value.map((r) => r.id))
      for (const item of batch) {
        if (!seen.has(item.id)) {
          remoteItems.value.push(item)
          seen.add(item.id)
        }
      }
    }
  }

  async function resetAndFetch() {
    loading.value = true
    lastLoadedPage.value = 0
    remoteItems.value = []
    try {
      await fetchPage(1, true)
    } finally {
      loading.value = false
    }
  }

  async function loadMore() {
    if (loading.value) return
    const next = lastLoadedPage.value + 1
    if (lastLoadedPage.value > 0 && next > totalPages.value) return

    loading.value = true
    try {
      await fetchPage(next, false)
    } finally {
      loading.value = false
    }
  }

  function setSeeds(items: T[] | null | undefined) {
    seeds.value = (items ?? []).filter((i) => i?.id)
  }

  function onListScroll(ev: Event) {
    const el = ev.target as HTMLElement
    if (el.scrollHeight - el.scrollTop - el.clientHeight > 48) return
    void loadMore()
  }

  return {
    search,
    loading,
    displayItems,
    setSeeds,
    resetAndFetch,
    loadMore,
    onListScroll,
  }
}
