import type { BreadcrumbItem } from '@/types/layout'
import { useI18n } from 'vue-i18n'
export function getHomeBreadcrumbs(t: ReturnType<typeof useI18n>['t']): BreadcrumbItem[] {
    return [
        {
            label: t('admin.home.title'),
        },
    ]
}
