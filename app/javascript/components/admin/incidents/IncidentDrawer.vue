<template>
  <Drawer v-model:open="open" direction="right">
    <DrawerContent
      class="flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full data-[vaul-drawer-direction=right]:sm:max-w-xl"
    >
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <div>
            <DrawerTitle>{{ t('admin.incidents.drawer.title') }}</DrawerTitle>
            <DrawerDescription>{{ t('admin.incidents.drawer.description') }}</DrawerDescription>
          </div>
          <DrawerClose as-child>
            <Button type="button" variant="ghost" size="icon" :aria-label="t('common.actions.cancel')">
              <X class="size-4" />
            </Button>
          </DrawerClose>
        </div>
      </DrawerHeader>

      <div v-if="incident" class="flex-1 space-y-5 overflow-y-auto px-4 py-5">
        <div class="space-y-1 rounded-lg border px-4 py-3">
          <p class="text-sm font-medium">{{ t(`admin.incidents.categories.${incident.category}`) }}</p>
          <p class="whitespace-pre-line text-sm">{{ incident.description }}</p>
          <p class="text-muted-foreground text-xs">
            {{ [incident.reported_by_name, incident.unit, incident.common_area].filter(Boolean).join(' · ') }}
          </p>
        </div>

        <div class="grid gap-4 sm:grid-cols-2">
          <div class="space-y-2">
            <Label for="incident-status">{{ t('admin.incidents.drawer.status') }}</Label>
            <NativeSelect id="incident-status" v-model="form.status" class="w-full">
              <NativeSelectOption v-for="status in statuses" :key="status" :value="status">
                {{ t(`admin.incidents.status.${status}`) }}
              </NativeSelectOption>
            </NativeSelect>
          </div>
          <div class="space-y-2">
            <Label for="incident-priority">{{ t('admin.incidents.drawer.priority') }}</Label>
            <NativeSelect id="incident-priority" v-model="form.priority" class="w-full">
              <NativeSelectOption v-for="priority in priorities" :key="priority" :value="priority">
                {{ t(`admin.incidents.priorities.${priority}`) }}
              </NativeSelectOption>
            </NativeSelect>
          </div>
        </div>

        <div class="space-y-2">
          <Label for="incident-assignee">{{ t('admin.incidents.drawer.assignee') }}</Label>
          <NativeSelect id="incident-assignee" v-model="form.assigned_to_person_id" class="w-full">
            <NativeSelectOption value="">{{ t('admin.incidents.drawer.unassigned') }}</NativeSelectOption>
            <NativeSelectOption v-for="person in assignees" :key="person.id" :value="person.id">
              {{ person.name }}
            </NativeSelectOption>
          </NativeSelect>
        </div>

        <div class="space-y-2">
          <Label for="incident-resolution">{{ t('admin.incidents.drawer.resolution') }}</Label>
          <Textarea id="incident-resolution" v-model="form.resolution" rows="4" maxlength="2000" />
          <p class="text-muted-foreground text-xs">{{ t('admin.incidents.drawer.resolution_help') }}</p>
        </div>

        <div v-if="errors.length" class="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-3">
          <p v-for="error in errors" :key="error" class="text-destructive text-sm">{{ error }}</p>
        </div>
      </div>

      <DrawerFooter class="shrink-0 border-t px-4 py-4">
        <div class="flex w-full justify-end gap-2">
          <Button type="button" variant="outline" :disabled="submitting" @click="open = false">
            {{ t('common.actions.cancel') }}
          </Button>
          <Button type="button" :disabled="submitting || !canSubmit" @click="save">
            <Loader2 v-if="submitting" class="size-4 animate-spin" />
            <Save v-else class="size-4" />
            {{ t('admin.incidents.drawer.save') }}
          </Button>
        </div>
      </DrawerFooter>
    </DrawerContent>
  </Drawer>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { router } from '@inertiajs/vue3'
import { Loader2, Save, X } from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import { Button } from '@/components/ui/button'
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerDescription,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer'
import { Label } from '@/components/ui/label'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { Textarea } from '@/components/ui/textarea'
import { admin_incident_path } from '@/routes'
import type { AdminIncident, IncidentAssignee, IncidentStatus, IncidentTab } from '@/types/incident'

const props = defineProps<{
  incident: AdminIncident | null
  tab: IncidentTab
  assignees: IncidentAssignee[]
  priorities: string[]
}>()

const open = defineModel<boolean>('open', { default: false })

const { t } = useI18n()
const statuses: IncidentStatus[] = ['open', 'in_progress', 'resolved', 'dismissed']
const submitting = ref(false)
const errors = ref<string[]>([])

const form = reactive({
  status: 'open' as IncidentStatus,
  priority: 'normal',
  assigned_to_person_id: '',
  resolution: '',
})

// Closing needs a resolution: it is what the reporter receives.
const canSubmit = computed(
  () => !['resolved', 'dismissed'].includes(form.status) || form.resolution.trim().length > 0,
)

watch(open, (isOpen) => {
  if (!isOpen || !props.incident) return

  form.status = props.incident.status
  form.priority = props.incident.priority
  form.assigned_to_person_id = props.incident.assigned_to_person_id ?? ''
  form.resolution = props.incident.resolution ?? ''
  errors.value = []
})

function save() {
  if (!props.incident || !canSubmit.value) return

  submitting.value = true
  errors.value = []

  router.patch(
    admin_incident_path(props.incident.id, { tab: props.tab }),
    {
      incident: {
        status: form.status,
        priority: form.priority,
        assigned_to_person_id: form.assigned_to_person_id || null,
        resolution: form.resolution.trim(),
      },
    },
    {
      preserveScroll: true,
      onSuccess: (page) => {
        const base = (page.props.errors as Record<string, string | string[]> | undefined)?.base
        if (base) {
          errors.value = Array.isArray(base) ? base : [base]
          return
        }
        open.value = false
        toast.success(t('admin.incidents.drawer.saved'))
      },
      onError: (errs) => {
        errors.value = Object.values(errs as Record<string, string | string[]>).flatMap((value) =>
          Array.isArray(value) ? value : [value],
        )
      },
      onFinish: () => {
        submitting.value = false
      },
    },
  )
}
</script>
