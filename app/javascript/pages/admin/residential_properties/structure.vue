<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div class="space-y-1">
        <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.residential_properties.structure.title')" />
        <p class="text-sm text-muted-foreground">
          {{ t('admin.residential_properties.structure.subtitle') }}
        </p>
      </div>
    </div>

    <div class="grid min-h-[32rem] grid-cols-1 gap-6 lg:grid-cols-2">
      <SectionTree
        v-model:search="treeSearch"
        :property-name="props.residential_property.name"
        :tree="props.section_tree"
        :selected-id="selectedSectionId"
        @add-root="startCreateRoot"
        @select="onSelectSection"
        @add-subsection="startCreateChild"
        @edit="startEdit"
        @delete="confirmDelete"
      />
      <StructureForm
        ref="formRef"
        :property-name="props.residential_property.name"
        :section-types="props.section_types"
        :parent-options="filteredParentOptions"
        :tree="props.section_tree"
        :mode="formMode"
        :editing-node="editingNode"
        :initial-placement="initialPlacement"
        :initial-parent-id="initialParentId"
        @submit="onSubmit"
        @cancel="resetFormState"
      >
        <template #upload-multiple-units>
          <Button variant="outline" class="shrink-0" @click="onCreateMultipleClick">
            <Plus class="size-4" />
            {{ t('admin.residential_properties.structure.create_multiple') }}
          </Button>
        </template>
      </StructureForm>
    </div>

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
import { router, usePage } from '@inertiajs/vue3'
import { useI18n } from 'vue-i18n'
import { Plus } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import BulkUnitsImportDrawer from '@/components/admin/bulk_units/BulkUnitsImportDrawer.vue'
import Header from '@/components/admin/layout/Header.vue'
import SectionTree from '@/components/admin/property_section/SectionTree.vue'
import StructureForm from '@/components/admin/property_section/StructureForm.vue'
import { Button } from '@/components/ui/button'
import { getPropertyStructureBreadcrumbs } from '@/lib/breadcrumbs/property_structure'
import { applyErrorsToFormRef } from '@/lib/composables/forms/apply_errors_to_form_ref'
import { usePropertySectionTree } from '@/lib/composables/property_section/usePropertySectionTree'
import type { PropertySectionStructureSchema } from '@/lib/schemas/property_section_structure'
import type { PropertySectionTreeNode } from '@/types/property_section'
import type { ResidentialProperty } from '@/types/residential_property'
import type { PropertySectionParentOption } from '@/types/property_section'
import {
  admin_residential_property_property_section_path,
  admin_residential_property_property_sections_path,
} from '@/routes'

const { t } = useI18n()
const page = usePage()

const props = defineProps<{
  residential_property: ResidentialProperty
  section_tree: PropertySectionTreeNode[]
  parent_options: PropertySectionParentOption[]
  section_types: string[]
  errors?: Record<string, string[]>
}>()

const formRef = ref<InstanceType<typeof StructureForm> | null>(null)
const treeSearch = ref('')
const formMode = ref<'create' | 'edit'>('create')
const editingNode = ref<PropertySectionTreeNode | null>(null)
const selectedSectionId = ref<string | null>(null)
const initialPlacement = ref<'root' | 'child'>('root')
const initialParentId = ref<string | null>(null)

const propertyId = computed(() => props.residential_property.id as string)

const itemsBreadcrumb = computed(() =>
  getPropertyStructureBreadcrumbs(t, propertyId.value, props.residential_property.name)
)

const bulkImportOpen = ref(false)

const treeRef = computed(() => props.section_tree)
const searchRef = computed(() => treeSearch.value)
const { findNodeById } = usePropertySectionTree(treeRef, searchRef)

const selectedSection = computed(() => {
  if (!selectedSectionId.value) return null

  return findNodeById(props.section_tree, selectedSectionId.value) ?? null
})

const filteredParentOptions = computed(() => {
  if (!editingNode.value) return props.parent_options
  return props.parent_options.filter((option) => option.id !== editingNode.value?.id)
})

function resetFormState() {
  formMode.value = 'create'
  editingNode.value = null
  selectedSectionId.value = null
  initialPlacement.value = 'root'
  initialParentId.value = null
}

function startCreateRoot() {
  resetFormState()
  initialPlacement.value = 'root'
  initialParentId.value = null
}

function onSelectSection(node: PropertySectionTreeNode) {
  selectedSectionId.value = node.id
}

function onCreateMultipleClick() {
  if (!selectedSection.value) {
    toast.error(t('admin.residential_properties.structure.bulk_import.select_section_first'))
    return
  }

  bulkImportOpen.value = true
}

function startCreateChild(parentId: string) {
  resetFormState()
  initialPlacement.value = 'child'
  initialParentId.value = parentId
  selectedSectionId.value = parentId
}

function startEdit(node: PropertySectionTreeNode) {
  formMode.value = 'edit'
  editingNode.value = node
  selectedSectionId.value = node.id
}

function confirmDelete(node: PropertySectionTreeNode) {
  if (!window.confirm(t('admin.property_sections.index.actions.delete_description', { name: node.name }))) {
    return
  }

  router.delete(
    admin_residential_property_property_section_path(propertyId.value, node.id),
    {
      onSuccess: () => {
        toast.success(t('admin.property_sections.index.actions.delete_success'))
        if (editingNode.value?.id === node.id) {
          resetFormState()
        }
      },
      onError: () => {
        toast.error(t('admin.property_sections.index.actions.delete_error'))
      },
    }
  )
}

function onSubmit(data: PropertySectionStructureSchema) {
  const payload = {
    property_section: {
      name: data.name,
      code: data.code,
      section_type: data.section_type,
      parent_id: data.placement === 'root' ? null : data.parent_id,
      position: data.position,
    },
  }

  if (formMode.value === 'edit' && editingNode.value) {
    router.put(
      admin_residential_property_property_section_path(propertyId.value, editingNode.value.id),
      payload,
      {
        preserveScroll: true,
        onSuccess: () => {
          toast.success(t('admin.property_sections.updated_successfully'))
          resetFormState()
        },
        onError: (errors) => {
          toast.error(t('admin.property_sections.update_failed'))
          applyErrorsToFormRef(formRef, errors)
        },
      }
    )
    return
  }

  router.post(admin_residential_property_property_sections_path(propertyId.value), payload, {
    preserveScroll: true,
    onSuccess: () => {
      toast.success(t('admin.property_sections.created_successfully'))
      resetFormState()
    },
    onError: (errors) => {
      toast.error(t('admin.property_sections.creation_failed'))
      applyErrorsToFormRef(formRef, errors)
    },
  })
}

onMounted(() => {
  const editId = new URL(page.url, window.location.origin).searchParams.get('edit')
  if (editId) {
    const node = findNodeById(props.section_tree, editId)
    if (node) startEdit(node)
  }

  if (props.errors && Object.keys(props.errors).length > 0) {
    applyErrorsToFormRef(formRef, props.errors)
  }
})
</script>
