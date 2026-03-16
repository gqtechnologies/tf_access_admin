<template>
    <SidebarMenu>
        <SidebarMenuItem>
            <DropdownMenu>
                <DropdownMenuTrigger asChild>
                    <SidebarMenuButton size="lg">
                        <Avatar class="h-8 w-8 rounded-lg">
                            <AvatarImage v-if="user?.image" :src="user?.image" :alt="user?.name" />
                            <AvatarFallback class="bg-gray-200 uppercase">{{ getUserFallback(user) }}</AvatarFallback>
                        </Avatar>
                        <div class="grid flex-1 text-left text-sm leading-tight">
                            <span class="truncate font-medium">{{ user?.name }}</span>
                            <span class="truncate text-xs text-muted-foreground">
                                {{ user?.email }}
                            </span>
                        </div>
                        <ChevronsUpDownIcon class="ml-auto size-4" />
                    </SidebarMenuButton>
                </DropdownMenuTrigger>
                <DropdownMenuContent side="right" align="end" :sideOffset="4" class="min-w-56">
                    <DropdownMenuLabel>{{ t('admin.sidebar.footer.title') }}</DropdownMenuLabel>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem class="cursor-pointer">
                        <Link :href="edit_admin_profile_path(user.id!)" class="w-full flex items-center gap-2">
                            <UserIcon /> {{ t('admin.sidebar.footer.profile') }}
                        </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem class="cursor-pointer" @click="handleLogout">
                        <LogOut /> {{ t('admin.sidebar.footer.logout') }}
                    </DropdownMenuItem>
                </DropdownMenuContent>
            </DropdownMenu>
        </SidebarMenuItem>
    </SidebarMenu>
</template>

<script setup lang="ts">
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { SidebarMenu, SidebarMenuItem, SidebarMenuButton } from '@/components/ui/sidebar'
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar'
import { LogOut, User as UserIcon, ChevronsUpDownIcon } from 'lucide-vue-next'
import { User } from '@/types/user'
import { getUserFallback } from '@/lib/user'
import { useI18n } from 'vue-i18n'
import { router } from '@inertiajs/vue3'
import { toast } from "vue-sonner"
import { user_session_path, destroy_user_session_path, edit_admin_profile_path } from '@/routes'
import { Link } from '@inertiajs/vue3'
const { user } = defineProps<{
    user: User
}>()
const { t } = useI18n()

const handleLogout = () => {
    router.delete(destroy_user_session_path(), {
        onSuccess: () => {
            router.visit(user_session_path())
        },
        onError: () => {
            toast.error(t('admin.sidebar.footer.logout_error'))
        }
    })
}
</script>