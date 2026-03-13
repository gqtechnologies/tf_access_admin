import type { ColumnDef, RowData } from "@tanstack/vue-table"

export type { ColumnDef, RowData }

export type TableMeta = {
  current_page: number
  per_page: number
  total_pages: number
  total_count: number
}

export type DataTablePaginationState = {
  currentPage: number
  totalPages: number
  totalItems: number
  itemsPerPage: number
  itemsPerPageOptions: number[]
  onPageChange: (page: number) => void
  onItemsPerPageChange: (perPage: number) => void
}