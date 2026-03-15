<template>
    <div class="flex items-center justify-center">
        <Empty>
            <EmptyHeader>
                <SearchXIcon class="size-16 mb-2" />
                <EmptyTitle>{{ t('not_found.title') }}</EmptyTitle>
                <EmptyDescription>{{ t('not_found.description') }}</EmptyDescription>
            </EmptyHeader>
            <EmptyContent>
                <EmptyDescription>
                    {{ t('not_found.need_help') }} <Link :href="admin_home_index_path()">{{ t('not_found.contact_support') }}</Link>
                </EmptyDescription>
            </EmptyContent>
        </Empty>
    </div>
</template>

<script setup lang="ts">
import { Empty, EmptyHeader, EmptyTitle, EmptyDescription } from '@/components/ui/empty'
import EmptyContent from '@/components/ui/empty/EmptyContent.vue';
import { SearchXIcon } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
import { Link } from '@inertiajs/vue3'
import { admin_home_index_path } from '@/routes'
const { t } = useI18n()
</script>