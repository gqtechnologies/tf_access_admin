import { ref } from 'vue'
import { useRailsFetch } from '@/lib/composables/useRailsFetch'
import type { Person } from '@/types/person'
import type { TableMeta } from '@/types/table'

type PeopleSearchResponse = {
  people: Person[]
  pagination: TableMeta
}

export function useUnitAddOwnerPeopleSearch() {
  const { railsFetchJson } = useRailsFetch()
  const people = ref<Person[]>([])
  const pagination = ref<TableMeta | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function search(query: string, page = 1, perPage = 10) {
    loading.value = true
    error.value = null

    const params = new URLSearchParams({
      page: String(page),
      per_page: String(perPage),
    })

    const trimmed = query.trim()
    if (trimmed) {
      params.set('q[display_name_or_first_name_or_last_name_cont]', trimmed)
    }

    try {
      const { res, data } = await railsFetchJson<PeopleSearchResponse>(
        'GET',
        `/admin/people?${params.toString()}`,
      )

      if (!res.ok) {
        error.value = 'search_failed'
        people.value = []
        pagination.value = null
        return
      }

      people.value = data.people ?? []
      pagination.value = data.pagination ?? null
    } finally {
      loading.value = false
    }
  }

  return {
    people,
    pagination,
    loading,
    error,
    search,
  }
}
