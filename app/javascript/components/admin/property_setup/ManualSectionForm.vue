<template>
  <div v-if="selectedMode === 'manual'" class="space-y-4 rounded-lg border p-4">
    <!-- Header: explains the two-level + leaf-units rule -->
    <div class="space-y-1">
      <p class="text-sm font-medium">{{ t('admin.property_setup.step2.manual.title') }}</p>
      <p class="text-muted-foreground text-xs">{{ t('admin.property_setup.step2.manual.rule_hint') }}</p>
    </div>

    <!-- Section count summary -->
    <div v-if="hasSections" class="text-muted-foreground flex gap-4 text-xs">
      <span>{{ t('admin.property_setup.step2.manual.summary.total', { count: totalCount }) }}</span>
      <span>{{ t('admin.property_setup.step2.manual.summary.leaf', { count: leafForUnitsCount }) }}</span>
    </div>

    <!-- Tree -->
    <ul v-if="hasSections" class="space-y-1 rounded-md border p-2 text-sm">
      <li v-for="root in tree" :key="root.id" class="space-y-1">
        <div class="flex items-center justify-between gap-2 rounded px-2 py-1.5 hover:bg-muted/50">
          <div class="flex min-w-0 items-center gap-2">
            <span class="truncate font-medium">{{ root.name }}</span>
            <Badge variant="secondary">{{ typeLabel(root.section_type) }}</Badge>
            <Badge variant="outline">{{ t('admin.property_setup.step2.manual.level.root') }}</Badge>
          </div>
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <Button variant="ghost" size="icon" :aria-label="t('admin.property_setup.step2.manual.actions.menu')">
                <MoreHorizontal class="size-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem @select="openEdit(root)">
                <Pencil class="size-4" />{{ t('admin.property_setup.step2.manual.actions.edit') }}
              </DropdownMenuItem>
              <DropdownMenuItem @select="openAddChild(root)">
                <Plus class="size-4" />{{ t('admin.property_setup.step2.manual.actions.add_child') }}
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem variant="destructive" @select="openDelete(root)">
                <Trash2 class="size-4" />{{ t('admin.property_setup.step2.manual.actions.delete') }}
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>

        <ul v-if="root.children?.length" class="space-y-1 pl-5">
          <li
            v-for="child in root.children"
            :key="child.id"
            class="flex items-center justify-between gap-2 rounded px-2 py-1.5 hover:bg-muted/50"
          >
            <div class="flex min-w-0 items-center gap-2">
              <span class="truncate">{{ child.name }}</span>
              <Badge variant="secondary">{{ typeLabel(child.section_type) }}</Badge>
              <Badge variant="outline">{{ t('admin.property_setup.step2.manual.level.child') }}</Badge>
            </div>
            <DropdownMenu>
              <DropdownMenuTrigger as-child>
                <Button variant="ghost" size="icon" :aria-label="t('admin.property_setup.step2.manual.actions.menu')">
                  <MoreHorizontal class="size-4" />
                </Button>
              </DropdownMenuTrigger>
              <!-- Child rows: no "add child" (third level not allowed) -->
              <DropdownMenuContent align="end">
                <DropdownMenuItem @select="openEdit(child)">
                  <Pencil class="size-4" />{{ t('admin.property_setup.step2.manual.actions.edit') }}
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem variant="destructive" @select="openDelete(child)">
                  <Trash2 class="size-4" />{{ t('admin.property_setup.step2.manual.actions.delete') }}
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </li>
        </ul>
      </li>
    </ul>

    <p v-if="!hasSections" class="text-muted-foreground text-sm">
      {{ t('admin.property_setup.step2.manual.empty') }}
    </p>

    <!-- The single visible creation button -->
    <Button type="button" @click="openAddRoot">
      <Plus class="size-4" />{{ t('admin.property_setup.step2.manual.add_root') }}
    </Button>

    <!-- Create sheet (root or child), Individual / Múltiple tabs -->
    <Sheet :open="createOpen" @update:open="onCreateOpenChange">
      <SheetContent class="flex flex-col gap-4 overflow-y-auto sm:max-w-md">
        <SheetHeader>
          <SheetTitle>
            {{ createParent
              ? t('admin.property_setup.step2.manual.create.title_child')
              : t('admin.property_setup.step2.manual.create.title_root') }}
          </SheetTitle>
          <SheetDescription v-if="createParent">
            {{ t('admin.property_setup.step2.manual.create.parent_label', { name: createParent.name }) }}
            — {{ t('admin.property_setup.step2.manual.create.child_no_children') }}
          </SheetDescription>
        </SheetHeader>

        <div class="flex flex-col gap-4 px-4">
          <Tabs v-model="createForm.mode">
            <TabsList class="w-full">
              <TabsTrigger value="individual" class="flex-1">
                {{ t('admin.property_setup.step2.manual.create.tab_individual') }}
              </TabsTrigger>
              <TabsTrigger value="multiple" class="flex-1">
                {{ t('admin.property_setup.step2.manual.create.tab_multiple') }}
              </TabsTrigger>
            </TabsList>

            <TabsContent value="individual" class="space-y-3 pt-3">
              <Field :data-invalid="!!createErrors.name">
                <FieldLabel>{{ t('admin.property_setup.step2.manual.name') }}</FieldLabel>
                <Input v-model="createForm.name" :aria-invalid="!!createErrors.name" />
                <FieldError v-if="createErrors.name" :errors="translateErrors([createErrors.name])" />
              </Field>
            </TabsContent>

            <TabsContent value="multiple" class="space-y-3 pt-3">
              <div class="grid grid-cols-2 gap-3">
                <Field :data-invalid="!!createErrors.prefix">
                  <FieldLabel>{{ t('admin.property_setup.step2.manual.create.prefix') }}</FieldLabel>
                  <Input v-model="createForm.prefix" :aria-invalid="!!createErrors.prefix" />
                  <FieldError v-if="createErrors.prefix" :errors="translateErrors([createErrors.prefix])" />
                </Field>
                <Field :data-invalid="!!createErrors.count">
                  <FieldLabel>{{ t('admin.property_setup.step2.manual.create.count') }}</FieldLabel>
                  <Input v-model="createForm.count" type="number" min="1" :aria-invalid="!!createErrors.count" />
                  <FieldError v-if="createErrors.count" :errors="translateErrors([createErrors.count])" />
                </Field>
              </div>
              <Field>
                <FieldLabel>{{ t('admin.property_setup.step2.manual.create.format') }}</FieldLabel>
                <select
                  v-model="createForm.suffix_type"
                  class="border-input bg-background flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                >
                  <option value="letter">{{ t('admin.property_setup.step2.manual.create.format_letter') }}</option>
                  <option value="number">{{ t('admin.property_setup.step2.manual.create.format_number') }}</option>
                </select>
              </Field>
              <div v-if="namePreview.length" class="rounded-md bg-muted/50 p-2 text-xs">
                <p class="text-muted-foreground mb-1">{{ t('admin.property_setup.step2.manual.create.preview') }}</p>
                <p class="font-medium">{{ namePreview.join(', ') }}</p>
              </div>
            </TabsContent>
          </Tabs>

          <!-- Shared fields -->
          <Field :data-invalid="!!createErrors.section_type">
            <FieldLabel>{{ t('admin.property_setup.step2.manual.type') }}</FieldLabel>
            <select
              v-model="createForm.section_type"
              class="border-input bg-background flex h-10 w-full rounded-md border px-3 py-2 text-sm"
              :aria-invalid="!!createErrors.section_type"
            >
              <option v-for="type in sectionTypes" :key="type" :value="type">{{ typeLabel(type) }}</option>
            </select>
            <FieldError v-if="createErrors.section_type" :errors="translateErrors([createErrors.section_type])" />
            <p v-if="showCreateFormatWarning" class="text-xs text-amber-600">
              {{ t('admin.property_setup.step2.manual.format_warning', { types: recommendedLabels }) }}
            </p>
          </Field>

          <Field v-if="createForm.mode === 'individual'">
            <FieldLabel>{{ t('admin.property_setup.step2.manual.create.code') }}</FieldLabel>
            <Input v-model="createForm.code" />
          </Field>
        </div>

        <SheetFooter>
          <Button type="button" :disabled="submitting" @click="submitCreate">
            {{ t('admin.property_setup.step2.manual.create.submit') }}
          </Button>
        </SheetFooter>
      </SheetContent>
    </Sheet>

    <!-- Edit sheet -->
    <Sheet :open="editOpen" @update:open="onEditOpenChange">
      <SheetContent class="flex flex-col gap-4 overflow-y-auto sm:max-w-md">
        <SheetHeader>
          <SheetTitle>{{ t('admin.property_setup.step2.manual.edit.title') }}</SheetTitle>
        </SheetHeader>
        <div class="flex flex-col gap-4 px-4">
          <Field :data-invalid="!!editErrors.name">
            <FieldLabel>{{ t('admin.property_setup.step2.manual.name') }}</FieldLabel>
            <Input v-model="editForm.name" :aria-invalid="!!editErrors.name" />
            <FieldError v-if="editErrors.name" :errors="translateErrors([editErrors.name])" />
          </Field>
          <Field :data-invalid="!!editErrors.section_type">
            <FieldLabel>{{ t('admin.property_setup.step2.manual.type') }}</FieldLabel>
            <select
              v-model="editForm.section_type"
              class="border-input bg-background flex h-10 w-full rounded-md border px-3 py-2 text-sm"
            >
              <option v-for="type in sectionTypes" :key="type" :value="type">{{ typeLabel(type) }}</option>
            </select>
          </Field>
          <Field>
            <FieldLabel>{{ t('admin.property_setup.step2.manual.create.code') }}</FieldLabel>
            <Input v-model="editForm.code" />
          </Field>
        </div>
        <SheetFooter>
          <Button type="button" :disabled="submitting" @click="submitEdit">
            {{ t('admin.property_setup.step2.manual.edit.submit') }}
          </Button>
        </SheetFooter>
      </SheetContent>
    </Sheet>

    <!-- Delete confirmation -->
    <AlertDialog :open="deleteOpen" @update:open="(v: boolean) => (deleteOpen = v)">
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>
            {{ t('admin.property_setup.step2.manual.delete.title', { name: deleteTarget?.name }) }}
          </AlertDialogTitle>
          <AlertDialogDescription>
            {{ t('admin.property_setup.step2.manual.delete.guards') }}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>{{ t('admin.property_setup.step2.manual.delete.cancel') }}</AlertDialogCancel>
          <AlertDialogAction :disabled="submitting" @click="submitDelete">
            {{ t('admin.property_setup.step2.manual.delete.confirm') }}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { router } from '@inertiajs/vue3'
import { useI18n } from 'vue-i18n'
import { MoreHorizontal, Pencil, Plus, Trash2 } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Field, FieldError, FieldLabel } from '@/components/ui/field'
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from '@/components/ui/sheet'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { useTranslateErrors } from '@/lib/composables/i18n/translate_errors'
import { mapPropertySetupZodErrors } from '@/lib/schemas/property_setup'
import {
  propertySectionBatchCreateSchema,
  propertySectionStructureEditSchema,
} from '@/lib/schemas/property_section_structure'
import { sectionNames, type SuffixType } from '@/lib/property_setup/structurePreview'

type SectionNode = {
  id: string
  name: string
  section_type: string
  children?: SectionNode[]
}

const props = defineProps<{
  propertyId: string
  sectionTypes: string[]
  recommendedSectionTypes?: string[]
  tree: SectionNode[]
  selectedMode: string
}>()

const { t } = useI18n()
const { translateErrors } = useTranslateErrors()
const submitting = ref(false)

const UNIT_ELIGIBLE_TYPES = ['block', 'tower', 'floor']

const hasSections = computed(() => props.tree.length > 0)
const totalCount = computed(() => props.tree.reduce((acc, root) => acc + 1 + (root.children?.length ?? 0), 0))
const leafForUnitsCount = computed(() => {
  let count = 0
  for (const root of props.tree) {
    const children = root.children ?? []
    if (children.length === 0) {
      if (UNIT_ELIGIBLE_TYPES.includes(root.section_type)) count += 1
    } else {
      count += children.filter((c) => UNIT_ELIGIBLE_TYPES.includes(c.section_type)).length
    }
  }
  return count
})

const recommended = computed(() => props.recommendedSectionTypes ?? [])
const recommendedLabels = computed(() =>
  recommended.value.map((type) => typeLabel(type)).join(', '),
)

function typeLabel(type: string) {
  return t(`admin.property_sections.section_types.${type}`)
}

// --- Create -----------------------------------------------------------------
const createOpen = ref(false)
const createParent = ref<SectionNode | null>(null)
const createErrors = ref<Record<string, string>>({})
const createForm = reactive({
  mode: 'individual' as 'individual' | 'multiple',
  name: '',
  section_type: props.sectionTypes[0] ?? 'tower',
  prefix: '',
  suffix_type: 'letter' as SuffixType,
  count: '2',
  code: '',
})

const namePreview = computed(() => {
  if (createForm.mode !== 'multiple') return []
  const count = Number(createForm.count)
  if (!createForm.prefix || Number.isNaN(count) || count < 1) return []
  return sectionNames(createForm.prefix, createForm.suffix_type, Math.min(count, 6))
})

const showCreateFormatWarning = computed(
  () => recommended.value.length > 0 && !recommended.value.includes(createForm.section_type),
)

function resetCreateForm() {
  createForm.mode = 'individual'
  createForm.name = ''
  createForm.section_type = props.sectionTypes[0] ?? 'tower'
  createForm.prefix = ''
  createForm.suffix_type = 'letter'
  createForm.count = '2'
  createForm.code = ''
  createErrors.value = {}
}

function openAddRoot() {
  createParent.value = null
  resetCreateForm()
  createOpen.value = true
}

function openAddChild(parent: SectionNode) {
  createParent.value = parent
  resetCreateForm()
  createForm.section_type = recommended.value[recommended.value.length - 1] ?? props.sectionTypes[0] ?? 'floor'
  createOpen.value = true
}

function onCreateOpenChange(value: boolean) {
  createOpen.value = value
  if (!value) createParent.value = null
}

function submitCreate() {
  const placement = createParent.value ? 'child' : 'root'
  const payload = {
    mode: createForm.mode,
    placement,
    section_type: createForm.section_type,
    parent_id: createParent.value?.id,
    name: createForm.mode === 'individual' ? createForm.name : undefined,
    code: createForm.code || undefined,
    prefix: createForm.mode === 'multiple' ? createForm.prefix : undefined,
    suffix_type: createForm.suffix_type,
    count: createForm.mode === 'multiple' ? createForm.count : undefined,
  }

  const result = propertySectionBatchCreateSchema.safeParse(payload)
  if (!result.success) {
    createErrors.value = mapPropertySetupZodErrors(result.error)
    return
  }

  createErrors.value = {}
  submitting.value = true
  router.post(
    `/admin/property_setup/wizard/${props.propertyId}/sections`,
    {
      property_section: {
        mode: createForm.mode,
        section_type: createForm.section_type,
        parent_id: createParent.value?.id ?? null,
        name: createForm.mode === 'individual' ? createForm.name : null,
        code: createForm.code || null,
        prefix: createForm.mode === 'multiple' ? createForm.prefix : null,
        suffix_type: createForm.suffix_type,
        count: createForm.mode === 'multiple' ? Number(createForm.count) : null,
      },
    },
    {
      preserveScroll: true,
      onSuccess: () => {
        createOpen.value = false
        createParent.value = null
      },
      onFinish: () => {
        submitting.value = false
      },
    },
  )
}

// --- Edit -------------------------------------------------------------------
const editOpen = ref(false)
const editTarget = ref<SectionNode | null>(null)
const editErrors = ref<Record<string, string>>({})
const editForm = reactive({ name: '', section_type: 'tower', code: '' })

function openEdit(section: SectionNode) {
  editTarget.value = section
  editForm.name = section.name
  editForm.section_type = section.section_type
  editForm.code = ''
  editErrors.value = {}
  editOpen.value = true
}

function onEditOpenChange(value: boolean) {
  editOpen.value = value
  if (!value) editTarget.value = null
}

function submitEdit() {
  if (!editTarget.value) return
  const isRoot = props.tree.some((root) => root.id === editTarget.value!.id)
  const result = propertySectionStructureEditSchema.safeParse({
    placement: isRoot ? 'root' : 'child',
    status: 'active',
    name: editForm.name,
    section_type: editForm.section_type,
    code: editForm.code || undefined,
  })
  if (!result.success) {
    editErrors.value = mapPropertySetupZodErrors(result.error)
    return
  }

  editErrors.value = {}
  submitting.value = true
  router.patch(
    `/admin/property_setup/wizard/${props.propertyId}/sections/${editTarget.value.id}`,
    {
      property_section: {
        name: editForm.name,
        section_type: editForm.section_type,
        code: editForm.code || null,
      },
    },
    {
      preserveScroll: true,
      onSuccess: () => {
        editOpen.value = false
        editTarget.value = null
      },
      onFinish: () => {
        submitting.value = false
      },
    },
  )
}

// --- Delete -----------------------------------------------------------------
const deleteOpen = ref(false)
const deleteTarget = ref<SectionNode | null>(null)

function openDelete(section: SectionNode) {
  deleteTarget.value = section
  deleteOpen.value = true
}

function submitDelete() {
  if (!deleteTarget.value) return
  submitting.value = true
  router.delete(
    `/admin/property_setup/wizard/${props.propertyId}/sections/${deleteTarget.value.id}`,
    {
      preserveScroll: true,
      onSuccess: () => {
        deleteOpen.value = false
        deleteTarget.value = null
      },
      onFinish: () => {
        submitting.value = false
      },
    },
  )
}
</script>
