<script setup lang="ts">
import { Button } from "@/components/ui/button"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import type { DataTablePaginationState } from "@/types/table"
import { ChevronLeft, ChevronRight } from "lucide-vue-next"
import { useI18n } from "vue-i18n"
const { t } = useI18n()

defineProps<DataTablePaginationState>()
</script>

<template>
  <div class="w-full flex items-center justify-end gap-4">
    <div class="flex items-center gap-6 lg:gap-8">
      <div class="flex items-center gap-2">
        <span class="text-sm font-medium">{{ t('common.table.pagination.rows_per_page') }}</span>
        <Select
          :model-value="String(itemsPerPage)"
          @update:model-value="(v) => v && onItemsPerPageChange(Number(v))"
        >
          <SelectTrigger class="h-8 w-[70px]">
            <SelectValue :placeholder="String(itemsPerPage)" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem
              v-for="opt in itemsPerPageOptions"
              :key="opt"
              :value="String(opt)"
            >
              {{ opt }}
            </SelectItem>
          </SelectContent>
        </Select>
      </div>
      <p class="text-sm font-medium tabular-nums">
        {{ t('common.table.pagination.current_page', {current_page: currentPage, total_pages: totalPages || 1 }) }}
      </p>
      <div class="flex items-center gap-2">
        <Button
          variant="outline"
          size="icon"
          class="size-8"
          :disabled="currentPage <= 1"
          @click="onPageChange(currentPage - 1)"
        >
          <ChevronLeft class="size-4" />
          <span class="sr-only">{{ t('common.table.pagination.previous') }}</span>
        </Button>
        <Button
          variant="outline"
          size="icon"
          class="size-8"
          :disabled="currentPage >= totalPages"
          @click="onPageChange(currentPage + 1)"
        >
          <ChevronRight class="size-4" />
          <span class="sr-only">{{ t('common.table.pagination.next') }}</span>
        </Button>
      </div>
    </div>
  </div>
</template>
