import type { BreadcrumbItem } from '@/types/layout'
import { admin_home_index_path } from '@/routes'
import { useI18n } from 'vue-i18n'
export function getProfileBreadcrumbs(t: ReturnType<typeof useI18n>['t']): BreadcrumbItem[] {
    return [
        {
            label: t('admin.home.title'),
            href: admin_home_index_path(),
        },
        {
            label: t('admin.profile.title'),
        },
    ]
}
