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
                        <DotsVertical class="ml-auto size-4" />
                    </SidebarMenuButton>
                </DropdownMenuTrigger>
                <DropdownMenuContent side="right" align="end" :sideOffset="4" class="min-w-56">
                    <DropdownMenuLabel>{{ t('sidebar.footer.title') }}</DropdownMenuLabel>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem class="cursor-pointer">
                        <UserIcon /> {{ t('sidebar.footer.profile') }}
                    </DropdownMenuItem>
                    <DropdownMenuItem class="cursor-pointer">
                        <LogOut /> {{ t('sidebar.footer.logout') }}
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
import { LogOut, User as UserIcon } from 'lucide-vue-next'
import { User } from '@/types/user'
import { getUserFallback } from '@/lib/user'
import { useI18n } from 'vue-i18n'
const { user } = defineProps<{
    user: User
}>()
const { t } = useI18n()
</script>