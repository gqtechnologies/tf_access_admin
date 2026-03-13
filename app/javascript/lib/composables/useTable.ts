// import { debounce } from "lodash"
import { onMounted, ref } from "vue"
import type { TableMeta } from "@/types/table"

export type UseTableOptions = {
  /** Initial pagination from server (e.g. Inertia props). */
  initialPagination?: TableMeta
  /** When true, do not call fetchData on mount (use when initial data comes from server). */
  skipInitialFetch?: boolean
}

export const useTable = (
  fetchData: (search: string, page: number, itemsPerPage: number) => void,
  options?: UseTableOptions
) => {
  const currentPage = ref(1)
  const itemsPerPage = ref(10)
  const totalItems = ref(0)
  const itemsPerPageOptions = ref([10, 20, 30, 40])
  const search = ref("")
  const totalPages = ref(1)

  const setPagination = (pagination: TableMeta) => {
    totalPages.value = pagination.total_pages
    currentPage.value = pagination.current_page
    itemsPerPage.value = pagination.per_page
    totalItems.value = pagination.total_count
  }

  onMounted(() => {
    if (options?.initialPagination) setPagination(options.initialPagination)
    if (!options?.skipInitialFetch) {
      fetchData(search.value, currentPage.value, itemsPerPage.value)
    }
  })

  const handlePageChange = (page: number) => {
    currentPage.value = page
    fetchData(search.value, page, itemsPerPage.value)
  }

  const handleItemsPerPageChange = (perPage: number) => {
    itemsPerPage.value = perPage
    fetchData(search.value, currentPage.value, perPage)
  }

  const clearSearch = () => {
    search.value = ""
    fetchData(search.value, currentPage.value, itemsPerPage.value)
  }

  return {
    currentPage,
    itemsPerPage,
    itemsPerPageOptions,
    search,
    totalPages,
    totalItems,
    handlePageChange,
    handleItemsPerPageChange,
    clearSearch,
    setPagination,
  }
}
