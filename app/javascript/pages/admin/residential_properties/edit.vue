<template>
  <div>
    <Header :itemsBreadcrumb="itemsBreadcrumb" :title="t('admin.residential_properties.edit.title')" />

    <div
      v-if="isArchived"
      class="border-muted-foreground/30 bg-muted/40 mb-4 rounded-lg border border-dashed px-4 py-3 text-sm"
      role="status"
    >
      {{ t('admin.residential_properties.edit.archived_banner') }}
    </div>

    <div
      v-else-if="!canUpdate"
      class="border-destructive/30 bg-destructive/5 mb-4 rounded-lg border px-4 py-3 text-sm"
      role="alert"
    >
      {{ t('admin.residential_properties.states.forbidden') }}
    </div>

    <Form
      ref="formRef"
      mode="edit"
      :description="t('admin.residential_properties.edit.description')"
      :submitLabel="t('admin.residential_properties.edit.submit')"
      :property-types="props.property_types"
      :server-errors="props.errors"
      :default-values="props.residential_property"
      :cancel-label="t('common.back')"
      :readonly="isReadOnly"
      :readonly-reason="readonlyReason"
      :submitting="isSubmitting"
      :show-actions="canUpdate"
      @submit="onSubmit"
    />

    <Card v-if="canArchive" class="mt-4 border-dashed">
      <CardHeader>
        <CardTitle class="text-base">
          {{ t('admin.residential_properties.edit.archive_section.title') }}
        </CardTitle>
        <CardDescription>
          {{ t('admin.residential_properties.edit.archive_section.description') }}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <ConfirmDialog
          :title="t('admin.residential_properties.index.actions.archive')"
          :description="
            t('admin.residential_properties.index.actions.archive_description', {
              name: props.residential_property.name,
            })
          "
          :on-confirm="archiveProperty"
        >
          <Button variant="outline" :disabled="isArchiving">
            <Loader2 v-if="isArchiving" class="mr-2 size-4 animate-spin" />
            <ArchiveIcon v-else class="mr-2 size-4" />
            {{ t('admin.residential_properties.index.actions.archive') }}
          </Button>
        </ConfirmDialog>
      </CardContent>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { ArchiveIcon, Loader2 } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import Header from '@/components/admin/layout/Header.vue'
import ConfirmDialog from '@/components/custom/dialogs/ConfirmDialog.vue'
import Form from '@/components/admin/residential_property/Form.vue'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { getResidentialPropertiesBreadcrumbs } from '@/lib/breadcrumbs/residential_property'
import { useResidentialPropertySubmit } from '@/lib/composables/residential_property/useResidentialPropertySubmit'
import { applyErrorsToFormRef } from '@/lib/composables/forms/apply_errors_to_form_ref'
import type {
  ResidentialPropertyCreateSchema,
  ResidentialPropertyEditSchema,
} from '@/lib/schemas/residential_property'
import type { ResidentialProperty } from '@/types/residential_property'

const { t } = useI18n()

const props = defineProps<{
  residential_property: ResidentialProperty
  property_types: string[]
  errors?: Record<string, string[]>
}>()

const formRef = ref<InstanceType<typeof Form> | null>(null)
const isArchiving = ref(false)
const itemsBreadcrumb = computed(() => getResidentialPropertiesBreadcrumbs(t))

const isArchived = computed(() => props.residential_property.status === 'archived')
const canUpdate = computed(() => props.residential_property.permissions?.update ?? false)
const canArchive = computed(() => props.residential_property.permissions?.archive ?? false)
const isReadOnly = computed(() => isArchived.value || !canUpdate.value)
const readonlyReason = computed(() => {
  if (isArchived.value) return t('admin.residential_properties.edit.archived_banner')
  if (!canUpdate.value) return t('admin.residential_properties.states.read_only')
  return undefined
})

const { isSubmitting, submitUpdate, submitArchive } = useResidentialPropertySubmit(formRef)

function onSubmit(data: ResidentialPropertyCreateSchema | ResidentialPropertyEditSchema) {
  if (!props.residential_property.id || isReadOnly.value) return
  submitUpdate(props.residential_property.id, data as ResidentialPropertyEditSchema)
}

function archiveProperty() {
  if (!props.residential_property.id || !canArchive.value) return
  isArchiving.value = true
  submitArchive(props.residential_property.id, {
    onFinish: () => {
      isArchiving.value = false
    },
  })
}

onMounted(() => {
  if (!props.errors || Object.keys(props.errors).length === 0) return
  applyErrorsToFormRef(formRef, props.errors)
  toast.error(t('admin.residential_properties.update_failed'))
})
</script>
