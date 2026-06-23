<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div class="space-y-1">
        <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.residential_properties.structure.title')" />
        <p class="text-muted-foreground text-sm">
          {{ t('admin.residential_properties.structure.subtitle') }}
        </p>
      </div>
    </div>

    <div
      v-if="propertyArchived"
      class="border-muted-foreground/30 bg-muted/40 rounded-lg border border-dashed px-4 py-3 text-sm"
      role="status"
    >
      {{ t('admin.residential_properties.structure.states.property_archived') }}
    </div>

    <div
      v-else-if="!canViewStructure"
      class="border-destructive/30 bg-destructive/5 rounded-lg border px-4 py-3 text-sm"
      role="alert"
    >
      {{ t('admin.residential_properties.structure.states.forbidden') }}
    </div>

    <div v-else class="grid min-h-[32rem] grid-cols-1 gap-6 lg:grid-cols-2">
      <SectionTree
        v-model:search="search"
        :property-name="props.residential_property.name"
        :property-status="props.residential_property.status"
        :residential-property-id="propertyId"
        :filtered-tree="filteredTree"
        :has-sections="hasSections"
        :selected-id="selectedId"
        :force-expanded="forceExpanded"
        :is-expanded="isExpanded"
        :can-create-root="canCreateRoot"
        :loading="isSubmitting"
        :read-only="!canManage"
        @add-root="startCreateRoot"
        @select="onSelectSection"
        @add-subsection="startCreateChild"
        @edit="startEdit"
        @move="openMoveDialog"
        @archive="openArchiveDialog"
        @toggle-expand="setExpanded"
      />

      <StructureForm
        :key="formMode"
        ref="formRef"
        :property-name="props.residential_property.name"
        :section-types="props.section_types"
        :parent-options="filteredParentOptions"
        :mode="formMode"
        :editing-node="editingNode"
        :initial-placement="initialPlacement"
        :initial-parent-id="initialParentId"
        :readonly="isFormReadOnly"
        :readonly-reason="formReadonlyReason"
        :submitting="isSubmitting"
        :show-actions="canManage && (formMode === 'create' ? canCreateRoot : canEditSelected)"
        :server-errors="props.errors"
        @submit="onSubmit"
        @cancel="resetFormState"
      >
        <template #upload-multiple-units>
          <Button
            v-if="canManage && selectedSection"
            variant="outline"
            class="shrink-0"
            @click="onCreateMultipleClick"
          >
            <Plus class="size-4" />
            {{ t('admin.residential_properties.structure.create_multiple') }}
          </Button>
        </template>
      </StructureForm>
    </div>

    <SectionMoveDialog
      v-model:open="moveDialogOpen"
      :node="moveTarget"
      :parent-options="moveParentOptions"
      :submitting="isSubmitting"
      @submit="onMoveSubmit"
    />

    <AlertDialog :open="archiveDialogOpen" @update:open="archiveDialogOpen = $event">
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>
            {{ t('admin.residential_properties.structure.archive.title') }}
          </AlertDialogTitle>
          <AlertDialogDescription>
            {{
              t('admin.residential_properties.structure.archive.description', {
                name: archiveTarget?.name ?? '',
              })
            }}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>{{ t('common.actions.cancel') }}</AlertDialogCancel>
          <AlertDialogAction @click="confirmArchive">
            {{ t('common.actions.continue') }}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>

    <BulkUnitsImportDrawer
      v-model:open="bulkImportOpen"
      :property-name="props.residential_property.name"
      :residential-property-id="propertyId"
      :property-section-id="selectedSection?.id ?? ''"
      :section-tree="props.section_tree"
      :selected-section="selectedSection"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { usePage } from '@inertiajs/vue3'
import { useI18n } from 'vue-i18n'
import { Plus } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import BulkUnitsImportDrawer from '@/components/admin/bulk_units/BulkUnitsImportDrawer.vue'
import Header from '@/components/admin/layout/Header.vue'
import SectionMoveDialog from '@/components/admin/property_section/SectionMoveDialog.vue'
import SectionTree from '@/components/admin/property_section/SectionTree.vue'
import StructureForm from '@/components/admin/property_section/StructureForm.vue'
import { Button } from '@/components/ui/button'
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
import { getPropertyStructureBreadcrumbs } from '@/lib/breadcrumbs/property_structure'
import { applyErrorsToFormRef } from '@/lib/composables/forms/apply_errors_to_form_ref'
import { usePropertySectionStructureState } from '@/lib/composables/property_section/usePropertySectionTree'
import { usePropertySectionSubmit } from '@/lib/composables/property_section/usePropertySectionSubmit'
import type { PropertySectionMoveSchema } from '@/lib/schemas/property_section_structure'
import type {
  PropertySectionStructureCreateSchema,
  PropertySectionStructureEditSchema,
} from '@/lib/schemas/property_section_structure'
import type {
  PropertySectionParentOption,
  PropertySectionStructurePermissions,
  PropertySectionTreeNode,
} from '@/types/property_section'
import type { ResidentialProperty } from '@/types/residential_property'

const { t } = useI18n()
const page = usePage()

const props = defineProps<{
  residential_property: ResidentialProperty
  section_tree: PropertySectionTreeNode[]
  parent_options: PropertySectionParentOption[]
  structure_permissions: PropertySectionStructurePermissions
  section_types: string[]
  section_statuses?: string[]
  errors?: Record<string, string[]>
}>()

const formRef = ref<InstanceType<typeof StructureForm> | null>(null)
const formMode = ref<'create' | 'edit'>('create')
const editingNode = ref<PropertySectionTreeNode | null>(null)
const initialPlacement = ref<'root' | 'child'>('root')
const initialParentId = ref<string | null>(null)
const moveDialogOpen = ref(false)
const moveTarget = ref<PropertySectionTreeNode | null>(null)
const archiveDialogOpen = ref(false)
const archiveTarget = ref<PropertySectionTreeNode | null>(null)
const bulkImportOpen = ref(false)

const propertyId = computed(() => props.residential_property.id as string)
const treeRef = computed(() => props.section_tree)

const {
  search,
  selectedId,
  selectedNode: selectedSection,
  filteredTree,
  hasSections,
  findNodeById,
  forceExpanded,
  selectNode,
  clearSelection,
  isExpanded,
  setExpanded,
  expandAncestors,
} = usePropertySectionStructureState(treeRef)

const itemsBreadcrumb = computed(() =>
  getPropertyStructureBreadcrumbs(t, propertyId.value, props.residential_property.name),
)

const { isSubmitting, submitCreate, submitUpdate, submitMove, submitArchive } =
  usePropertySectionSubmit(formRef)

const propertyArchived = computed(() => props.residential_property.status === 'archived')
const canViewStructure = computed(() => props.structure_permissions.view)
const canManage = computed(() => props.structure_permissions.manage)
const canCreateRoot = computed(() => props.structure_permissions.create_root)

const canEditSelected = computed(() => {
  if (!editingNode.value) return false
  return editingNode.value.permissions.edit && !editingNode.value.disabled
})

const isFormReadOnly = computed(() => {
  if (!canManage.value) return true
  if (formMode.value === 'edit' && editingNode.value) {
    return !editingNode.value.permissions.edit || editingNode.value.disabled
  }
  return false
})

const formReadonlyReason = computed(() => {
  if (!canManage.value) return t('admin.residential_properties.structure.states.read_only')
  if (editingNode.value?.status === 'archived') {
    return t('admin.residential_properties.structure.states.section_archived')
  }
  if (editingNode.value?.disabled) {
    return t('admin.residential_properties.structure.states.section_not_operative')
  }
  return undefined
})

const filteredParentOptions = computed(() => {
  if (!editingNode.value) return props.parent_options
  return props.parent_options.filter((option) => option.id !== editingNode.value?.id)
})

const moveParentOptions = computed(() => {
  if (!moveTarget.value) return props.parent_options
  return props.parent_options.filter((option) => option.id !== moveTarget.value?.id)
})

function resetFormState() {
  formMode.value = 'create'
  editingNode.value = null
  clearSelection()
  initialPlacement.value = 'root'
  initialParentId.value = null
}

function startCreateRoot() {
  if (!canCreateRoot.value) return
  resetFormState()
  initialPlacement.value = 'root'
  initialParentId.value = null
}

function onSelectSection(node: PropertySectionTreeNode) {
  selectNode(node)
}

function onCreateMultipleClick() {
  if (!selectedSection.value) {
    toast.error(t('admin.residential_properties.structure.bulk_import.select_section_first'))
    return
  }
  bulkImportOpen.value = true
}

function startCreateChild(parentId: string) {
  if (!canManage.value) return
  const parent = findNodeById(props.section_tree, parentId)
  if (!parent?.permissions.add_child) return

  resetFormState()
  formMode.value = 'create'
  initialPlacement.value = 'child'
  initialParentId.value = parentId
  selectedId.value = parentId
  expandAncestors(parentId)
}

function startEdit(node: PropertySectionTreeNode) {
  if (!node.permissions.edit) return
  formMode.value = 'edit'
  editingNode.value = node
  selectedId.value = node.id
  expandAncestors(node.id)
}

function openMoveDialog(node: PropertySectionTreeNode) {
  if (!node.permissions.move) return
  moveTarget.value = node
  moveDialogOpen.value = true
}

function openArchiveDialog(node: PropertySectionTreeNode) {
  if (!node.permissions.archive) return
  archiveTarget.value = node
  archiveDialogOpen.value = true
}

function onMoveSubmit(data: PropertySectionMoveSchema) {
  if (!moveTarget.value) return
  const targetId = moveTarget.value.id
  submitMove(propertyId.value, targetId, data, {
    onSuccess: () => {
      moveDialogOpen.value = false
      moveTarget.value = null
      if (editingNode.value?.id === targetId) resetFormState()
    },
  })
}

function confirmArchive() {
  if (!archiveTarget.value) return
  const targetId = archiveTarget.value.id
  submitArchive(propertyId.value, targetId, {
    onSuccess: () => {
      archiveDialogOpen.value = false
      archiveTarget.value = null
      if (editingNode.value?.id === targetId) resetFormState()
    },
  })
}

function onSubmit(
  data: PropertySectionStructureCreateSchema | PropertySectionStructureEditSchema,
) {
  if (isFormReadOnly.value) return

  if (formMode.value === 'edit' && editingNode.value) {
    submitUpdate(propertyId.value, editingNode.value.id, data as PropertySectionStructureEditSchema)
    return
  }

  submitCreate(propertyId.value, data as PropertySectionStructureCreateSchema)
}

onMounted(() => {
  const editId = new URL(page.url, window.location.origin).searchParams.get('edit')
  if (editId) {
    const node = findNodeById(props.section_tree, editId)
    if (node) startEdit(node)
  }

  if (props.errors && Object.keys(props.errors).length > 0) {
    applyErrorsToFormRef(formRef, props.errors)
    const firstError = Object.values(props.errors).flat()[0]
    if (firstError) toast.error(firstError)
  }
})
</script>
