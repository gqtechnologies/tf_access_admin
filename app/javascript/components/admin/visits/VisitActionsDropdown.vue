<template>
  <DropdownMenu>
    <DropdownMenuTrigger as-child>
      <Button variant="ghost" size="icon" class="h-8 w-8 p-0">
        <EllipsisVertical class="size-4" />
        <span class="sr-only">{{ t('admin.visits.actions.open_menu') }}</span>
      </Button>
    </DropdownMenuTrigger>
    <DropdownMenuContent align="end" class="w-52">
      <DropdownMenuItem v-if="visit.permissions.show" as-child>
        <Link :href="admin_visit_path(visit.id)" class="flex w-full cursor-pointer items-center gap-2">
          <Eye class="size-4" />
          {{ t('admin.visits.actions.view') }}
        </Link>
      </DropdownMenuItem>
      <DropdownMenuItem v-if="visit.permissions.authorize" @select.prevent>
        <ConfirmDialog
          :title="t('admin.visits.actions.authorize_confirm_title')"
          :description="t('admin.visits.actions.authorize_confirm_description')"
          :on-confirm="authorizeVisit"
        >
          <div class="flex w-full cursor-pointer items-center gap-2">
            <ShieldCheck class="size-4" />
            {{ t('admin.visits.actions.authorize') }}
          </div>
        </ConfirmDialog>
      </DropdownMenuItem>
      <DropdownMenuItem v-if="visit.permissions.update" as-child>
        <Link :href="edit_admin_visit_path(visit.id)" class="flex w-full cursor-pointer items-center gap-2">
          <Pencil class="size-4" />
          {{ t('admin.visits.actions.edit') }}
        </Link>
      </DropdownMenuItem>
      <DropdownMenuItem v-if="visit.permissions.check_in" class="cursor-pointer" @select="emit('checkIn', visit)">
        <LogIn class="size-4" />
        {{ t('admin.visits.actions.check_in') }}
      </DropdownMenuItem>
      <DropdownMenuItem v-if="visit.permissions.check_out" class="cursor-pointer" @select="emit('checkOut', visit)">
        <LogOut class="size-4" />
        {{ t('admin.visits.actions.check_out') }}
      </DropdownMenuItem>
      <DropdownMenuItem v-if="visit.permissions.cancel" @select.prevent>
        <ConfirmDialog
          :title="t('admin.visits.actions.cancel_confirm_title')"
          :description="t('admin.visits.actions.cancel_confirm_description')"
          :on-confirm="cancelVisit"
        >
          <div class="text-destructive flex w-full cursor-pointer items-center gap-2">
            <Ban class="size-4" />
            {{ t('admin.visits.actions.cancel') }}
          </div>
        </ConfirmDialog>
      </DropdownMenuItem>
    </DropdownMenuContent>
  </DropdownMenu>
</template>

<script setup lang="ts">
import { Link, router } from '@inertiajs/vue3'
import { useI18n } from 'vue-i18n'
import { Ban, EllipsisVertical, Eye, LogIn, LogOut, Pencil, ShieldCheck } from 'lucide-vue-next'
import ConfirmDialog from '@/components/custom/dialogs/ConfirmDialog.vue'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { admin_visit_path, authorize_admin_visit_path, cancel_admin_visit_path, edit_admin_visit_path } from '@/routes'
import type { AdminVisitListItem } from '@/types/visit'

const props = defineProps<{
  visit: AdminVisitListItem
}>()

const emit = defineEmits<{
  checkIn: [visit: AdminVisitListItem]
  checkOut: [visit: AdminVisitListItem]
  success: []
}>()

const { t } = useI18n()

function authorizeVisit() {
  router.post(authorize_admin_visit_path(props.visit.id), {}, {
    onSuccess: () => emit('success'),
  })
}

function cancelVisit() {
  router.delete(cancel_admin_visit_path(props.visit.id), {
    onSuccess: () => emit('success'),
  })
}
</script>
