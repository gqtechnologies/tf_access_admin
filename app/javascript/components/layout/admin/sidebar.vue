<script setup lang="ts">
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarInset,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarProvider,
  SidebarRail,
  SidebarTrigger,
} from '@/components/ui/sidebar'
import { Home, GalleryVerticalEnd, Users, Settings, Building, Building2 } from 'lucide-vue-next';
import { Link } from '@inertiajs/vue3';
import NavUser from '@/components/admin/user/nav/NavUser.vue'
import { useI18n } from 'vue-i18n'
import { usePage } from '@inertiajs/vue3'
import { FeatureItem } from '@/types/auth'
const { t } = useI18n()
const page = usePage()
const features = page.props.auth.features as FeatureItem[]

const getFeatureIcon = (key: string) => {
  switch (key) {
    case 'home':
      return Home
    case 'users':
      return Users
    case 'organizations':
        return Building
    case 'residential_properties':
      return Building2
    case 'organization_settings':
      return Settings
    case 'settings':
        return Settings
  }
  return null
}
</script>

<template>
  <SidebarProvider>
    <Sidebar>
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton size="lg">
              <div class="flex aspect-square size-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground">
                <GalleryVerticalEnd class="size-4" />
              </div>
              <div class="grid flex-1 text-left text-sm leading-tight">
                <span class="truncate font-semibold capitalize">{{ t('name') }}</span>
                <span class="truncate text-xs capitalize">{{ t('description') }}</span>
              </div>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>{{ t('admin.sidebar.platform') }}</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>

              <SidebarMenuItem v-for="feature in features" :key="feature.key">
                <SidebarMenuButton as-child>
                  <Link :href="feature.url">
                    <component :is="getFeatureIcon(feature.key)" />
                    <span>{{ t(`admin.sidebar.${feature.key}`) }}</span>
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      <SidebarFooter>
        <NavUser />
      </SidebarFooter>
      <SidebarRail />
    </Sidebar>
    <SidebarInset>
      <header class="flex h-16 shrink-0 items-center gap-2 transition-[width,height] ease-linear group-has-[[data-collapsible=icon]]/sidebar-wrapper:h-12">
        <div class="flex items-center gap-2 px-4">
          <SidebarTrigger class="-ml-1" />
        </div>
      </header>
      <div class="flex flex-1 flex-col gap-4 p-4 pt-0">
        <slot />
      </div>
    </SidebarInset>
  </SidebarProvider>
</template>
