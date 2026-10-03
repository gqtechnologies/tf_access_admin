<template>
  <Drawer v-model:open="open" direction="right">
    <DrawerContent
      class="flex h-full max-h-screen flex-col data-[vaul-drawer-direction=right]:w-full data-[vaul-drawer-direction=right]:sm:max-w-xl"
    >
      <DrawerHeader class="shrink-0 border-b pb-4">
        <div class="flex items-start justify-between gap-4">
          <div>
            <DrawerTitle>
              {{ announcement ? t('admin.announcements.form.edit_title') : t('admin.announcements.form.new_title') }}
            </DrawerTitle>
            <DrawerDescription>{{ t('admin.announcements.form.description') }}</DrawerDescription>
          </div>
          <DrawerClose as-child>
            <Button type="button" variant="ghost" size="icon" :aria-label="t('common.actions.cancel')">
              <X class="size-4" />
            </Button>
          </DrawerClose>
        </div>
      </DrawerHeader>

      <div class="flex-1 space-y-4 overflow-y-auto px-4 py-5">
        <div class="space-y-2">
          <Label for="announcement-title">{{ t('admin.announcements.form.title') }}</Label>
          <Input id="announcement-title" v-model="form.title" maxlength="150" />
        </div>

        <div class="space-y-2">
          <Label for="announcement-content">{{ t('admin.announcements.form.content') }}</Label>
          <Textarea id="announcement-content" v-model="form.content" rows="8" maxlength="5000" />
          <p class="text-muted-foreground text-xs">{{ form.content.length }}/5000</p>
        </div>

        <div class="grid gap-4 sm:grid-cols-2">
          <div class="space-y-2">
            <Label for="announcement-category">{{ t('admin.announcements.form.category') }}</Label>
            <NativeSelect id="announcement-category" v-model="form.category" class="w-full">
              <NativeSelectOption v-for="category in categories" :key="category" :value="category">
                {{ t(`admin.announcements.categories.${category}`) }}
              </NativeSelectOption>
            </NativeSelect>
          </div>

          <div class="space-y-2">
            <Label for="announcement-priority">{{ t('admin.announcements.form.priority') }}</Label>
            <NativeSelect id="announcement-priority" v-model="form.priority" class="w-full">
              <NativeSelectOption v-for="priority in priorities" :key="priority" :value="priority">
                {{ t(`admin.announcements.priorities.${priority}`) }}
              </NativeSelectOption>
            </NativeSelect>
          </div>
        </div>

        <div class="space-y-2">
          <Label for="announcement-expires">{{ t('admin.announcements.form.expires_at') }}</Label>
          <Input id="announcement-expires" v-model="form.expires_at" type="date" />
          <p class="text-muted-foreground text-xs">{{ t('admin.announcements.form.expires_at_help') }}</p>
        </div>

        <label
          for="announcement-ack"
          class="flex cursor-pointer items-start justify-between gap-4 rounded-lg border px-4 py-3"
        >
          <span class="space-y-0.5">
            <span class="block text-sm font-medium">{{ t('admin.announcements.form.requires_acknowledgement') }}</span>
            <span class="text-muted-foreground block text-xs">
              {{ t('admin.announcements.form.requires_acknowledgement_help') }}
            </span>
          </span>
          <Checkbox
            id="announcement-ack"
            :model-value="form.requires_acknowledgement"
            @update:model-value="(value: boolean | 'indeterminate') => (form.requires_acknowledgement = value === true)"
          />
        </label>

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
            {{ t('admin.announcements.form.save') }}
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
import { Checkbox } from '@/components/ui/checkbox'
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerDescription,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { NativeSelect, NativeSelectOption } from '@/components/ui/native-select'
import { Textarea } from '@/components/ui/textarea'
import { admin_announcement_path, admin_announcements_path } from '@/routes'
import type { AdminAnnouncement, AnnouncementFormValues } from '@/types/announcement'

const props = defineProps<{
  /** The draft being edited; null to write a new one. */
  announcement: AdminAnnouncement | null
  propertyId: string
  categories: string[]
  priorities: string[]
}>()

const open = defineModel<boolean>('open', { default: false })

const { t } = useI18n()
const submitting = ref(false)
const errors = ref<string[]>([])

const form = reactive<AnnouncementFormValues>({
  title: '',
  content: '',
  category: 'general',
  priority: 'normal',
  requires_acknowledgement: false,
  expires_at: '',
})

const canSubmit = computed(() => form.title.trim().length > 0 && form.content.trim().length > 0)

watch(open, (isOpen) => {
  if (!isOpen) return

  const current = props.announcement
  form.title = current?.title ?? ''
  form.content = current?.content ?? ''
  form.category = current?.category ?? props.categories[0] ?? 'general'
  form.priority = current?.priority ?? 'normal'
  form.requires_acknowledgement = current?.requires_acknowledgement ?? false
  form.expires_at = current?.expires_at ? current.expires_at.slice(0, 10) : ''
  errors.value = []
})

function save() {
  if (!canSubmit.value) return

  submitting.value = true
  errors.value = []

  const data = {
    announcement: {
      title: form.title.trim(),
      content: form.content.trim(),
      category: form.category,
      priority: form.priority,
      requires_acknowledgement: form.requires_acknowledgement,
      // End of the chosen day: the announcement stays visible all of it.
      expires_at: form.expires_at ? `${form.expires_at}T23:59:59` : null,
    },
  }
  const options = {
    preserveScroll: true,
    onSuccess: () => {
      open.value = false
      toast.success(t('admin.announcements.form.saved'))
    },
    onError: (errs: Record<string, string | string[]>) => {
      errors.value = Object.values(errs).flatMap((value) => (Array.isArray(value) ? value : [value]))
    },
    onFinish: () => {
      submitting.value = false
    },
  }

  if (props.announcement) {
    router.patch(admin_announcement_path(props.announcement.id), data, options)
  } else {
    router.post(admin_announcements_path({ property_id: props.propertyId }), data, options)
  }
}
</script>
