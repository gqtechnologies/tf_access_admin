<script setup lang="ts" generic="TData extends object">
import { computed } from "vue"
import {
  useVueTable,
  FlexRender,
  getCoreRowModel,
  type ColumnDef,
} from "@tanstack/vue-table"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { TableEmpty } from "@/components/ui/table"
import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
} from "@/components/ui/card"
import { Popover, PopoverTrigger, PopoverContent } from "@/components/ui/popover"
import { useI18n } from "vue-i18n"
import { useSlots } from "vue"
import { Button } from "@/components/ui/button"
import { EllipsisVertical } from "lucide-vue-next"

const { t } = useI18n()
const slots = useSlots()

const props = withDefaults(
  defineProps<{
    columns: ColumnDef<TData, any>[]
    data: TData[]
    title?: string
    description?: string
    emptyMessage?: string
    /** Key on each row used as unique id (default: 'id') */
    rowIdKey?: string
    /** Header text for the actions column (used when #actions slot is provided) */
    actionsHeader?: string
  }>(),
  {
    rowIdKey: "id",
  }
)

const effectiveColumns = computed<ColumnDef<TData, any>[]>(() => {
  const cols = [...props.columns]
  if (slots.actions) {
    cols.push({
      id: "actions",
      header: () => props.actionsHeader ?? t("common.table.actions"),
      cell: () => null,
    } as ColumnDef<TData, any>)
  }
  return cols
})

const table = useVueTable({
  get data() {
    return props.data
  },
  get columns() {
    return effectiveColumns.value
  },
  getCoreRowModel: getCoreRowModel(),
  getRowId: (row: TData) => {
    const record = row as Record<string, unknown>
    const id = record[props.rowIdKey]
    return id != null ? String(id) : String(Math.random())
  },
})
</script>

<template>
  <Card class="border-none">
    <CardHeader>
      <CardTitle v-if="title">{{ title }}</CardTitle>
      <CardDescription v-if="description">{{ description }}</CardDescription>
    </CardHeader>
    <CardContent>
      <template v-if="$slots['actions-table']">
        <div class="flex justify-end mb-4">
          <slot name="actions-table" />
        </div>
      </template>
      <div class="overflow-hidden rounded-md border">
        <Table>
          <TableHeader>
            <TableRow
              v-for="headerGroup in table.getHeaderGroups()"
              :key="headerGroup.id"
            >
              <TableHead
                v-for="header in headerGroup.headers"
                :key="header.id"
                :colspan="header.colSpan"
                class="[&:has([role=checkbox])]:pr-0"
              >
                <FlexRender
                  v-if="!header.isPlaceholder"
                  :render="header.column.columnDef.header"
                  :props="header.getContext()"
                />
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            <template v-if="table.getRowModel().rows?.length">
              <TableRow
                v-for="row in table.getRowModel().rows"
                :key="row.id"
                :data-state="row.getIsSelected() && 'selected'"
              >
                <TableCell
                  v-for="cell in row.getVisibleCells()"
                  :key="cell.id"
                  class="[&:has([role=checkbox])]:pr-0"
                >
                  <template v-if="cell.column.id === 'actions' && $slots.actions">
                    <Popover>
                      <PopoverTrigger><Button variant="ghost" size="icon" class="h-8 w-8 p-0 cursor-pointer"><EllipsisVertical class="size-4" /></Button></PopoverTrigger>
                      <PopoverContent class="w-42 p-2"><slot name="actions" :row="row.original" /></PopoverContent>
                    </Popover>
                    
                  </template>
                  <FlexRender
                    v-else
                    :render="cell.column.columnDef.cell ?? ((ctx: { getValue: () => unknown }) => ctx.getValue())"
                    :props="cell.getContext()"
                  />
                </TableCell>
              </TableRow>
            </template>
            <template v-else>
              <TableEmpty
                :colspan="effectiveColumns.length"
                class="h-24"
              >
                {{ t(emptyMessage ?? 'common.table.empty_message') }}
              </TableEmpty>
            </template>
          </TableBody>
        </Table>
      </div>
    </CardContent>
    <CardFooter v-if="$slots.footer" class="flex flex-col gap-2 justify-end w-full">
      <slot name="footer" />
    </CardFooter>
  </Card>
</template>
