import type { BreadcrumbItem } from '@/types/layout'
import {
  admin_home_index_path,
  admin_residential_properties_path,
  admin_residential_property_structure_path,
} from '@/routes'
import { useI18n } from 'vue-i18n'

export function getPropertyStructureBreadcrumbs(
  t: ReturnType<typeof useI18n>['t'],
  residentialPropertyId: string,
  propertyName: string
): BreadcrumbItem[] {
  return [
    {
      label: t('admin.home.title'),
      href: admin_home_index_path(),
    },
    {
      label: t('admin.residential_properties.index.title'),
      href: admin_residential_properties_path(),
    },
    {
      label: propertyName,
      href: admin_residential_property_structure_path(residentialPropertyId),
    },
    {
      label: t('admin.residential_properties.structure.breadcrumb'),
    },
  ]
}
