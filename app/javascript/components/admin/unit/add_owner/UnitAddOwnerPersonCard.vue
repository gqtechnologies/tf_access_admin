<template>
  <div class="rounded-lg border bg-card p-4">
    <div class="flex items-start gap-3">
      <Avatar class="size-12">
        <AvatarFallback>{{ initials }}</AvatarFallback>
      </Avatar>
      <div class="min-w-0 flex-1 space-y-3">
        <div class="flex flex-wrap items-center gap-2">
          <h4 class="text-base font-semibold">{{ person.display_name }}</h4>
          <Badge variant="secondary">
            {{ t('admin.units.show.owners.add_owner.assign.existing_person_badge') }}
          </Badge>
        </div>
        <p v-if="person.document_number" class="text-sm font-medium text-primary">
          {{ person.document_number }}
        </p>
        <dl class="grid gap-2 text-sm">
          <div class="flex justify-between gap-4">
            <dt class="text-muted-foreground">{{ t('admin.people.input.email.label') }}</dt>
            <dd class="text-right font-medium">{{ person.email || '—' }}</dd>
          </div>
          <div v-if="person.phone" class="flex justify-between gap-4">
            <dt class="text-muted-foreground">{{ t('admin.people.input.phone.label') }}</dt>
            <dd class="text-right font-medium">{{ person.phone }}</dd>
          </div>
        </dl>
        <div v-if="showChangeAction" class="flex justify-end">
          <Button type="button" variant="outline" size="sm" @click="emit('change-person')">
            {{ t('admin.units.show.owners.add_owner.assign.change_person') }}
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { personInitials } from '@/lib/utils/unit'
import type { Person } from '@/types/person'

const props = withDefaults(
  defineProps<{
    person: Person
    showChangeAction?: boolean
  }>(),
  { showChangeAction: true },
)

const emit = defineEmits<{
  (e: 'change-person'): void
}>()

const { t } = useI18n()

const initials = computed(() => personInitials(props.person.display_name))
</script>
