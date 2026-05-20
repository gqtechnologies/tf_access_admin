import type { BreadcrumbItem } from '@/types/layout'
import { admin_home_index_path, admin_property_sections_path } from '@/routes'
import { useI18n } from 'vue-i18n'

export function getPropertySectionsBreadcrumbs(t: ReturnType<typeof useI18n>['t']): BreadcrumbItem[] {
  return [
    {
      label: t('admin.home.title'),
      href: admin_home_index_path(),
    },
    {
      label: t('admin.property_sections.index.title'),
      href: admin_property_sections_path(),
    },
  ]
}
