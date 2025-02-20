<script>
import { GlButton, GlEmptyState, GlLink, GlLoadingIcon, GlTable } from '@gitlab/ui';

import { s__, __ } from '~/locale';
import createFlash from '~/flash';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { getBulkImportsHistory } from '~/rest_api';
import ImportStatus from '~/import_entities/components/import_status.vue';
import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

import { DEFAULT_ERROR } from '../utils/error_messages';

const DEFAULT_PER_PAGE = 20;
const DEFAULT_TH_CLASSES =
  'gl-bg-transparent! gl-border-b-solid! gl-border-b-gray-200! gl-border-b-1! gl-p-5!';

const HISTORY_PAGINATION_SIZE_PERSIST_KEY = 'gl-bulk-imports-history-per-page';

const tableCell = (config) => ({
  thClass: `${DEFAULT_TH_CLASSES}`,
  tdClass: (value, key, item) => {
    return {
      // eslint-disable-next-line no-underscore-dangle
      'gl-border-b-0!': item._showDetails,
    };
  },
  ...config,
});

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    GlLoadingIcon,
    GlTable,
    PaginationBar,
    ImportStatus,
    TimeAgo,
    LocalStorageSync,
  },

  data() {
    return {
      loading: true,
      historyItems: [],
      paginationConfig: {
        page: 1,
        perPage: DEFAULT_PER_PAGE,
      },
      pageInfo: {},
    };
  },

  fields: [
    tableCell({
      key: 'source_full_path',
      label: s__('BulkImport|Source group'),
      thClass: `${DEFAULT_TH_CLASSES} gl-w-30p`,
    }),
    tableCell({
      key: 'destination_name',
      label: s__('BulkImport|Destination group'),
      thClass: `${DEFAULT_TH_CLASSES} gl-w-40p`,
    }),
    tableCell({
      key: 'created_at',
      label: __('Date'),
    }),
    tableCell({
      key: 'status',
      label: __('Status'),
      tdAttr: { 'data-qa-selector': 'import_status_indicator' },
    }),
  ],

  computed: {
    hasHistoryItems() {
      return this.historyItems.length > 0;
    },
  },

  watch: {
    paginationConfig: {
      handler() {
        this.loadHistoryItems();
      },
      deep: true,
    },
  },

  mounted() {
    this.loadHistoryItems();
  },

  methods: {
    async loadHistoryItems() {
      try {
        this.loading = true;
        const { data: historyItems, headers } = await getBulkImportsHistory({
          page: this.paginationConfig.page,
          per_page: this.paginationConfig.perPage,
        });
        this.pageInfo = parseIntPagination(normalizeHeaders(headers));
        this.historyItems = historyItems;
      } catch (e) {
        createFlash({ message: DEFAULT_ERROR, captureError: true, error: e });
      } finally {
        this.loading = false;
      }
    },

    getDestinationUrl({ destination_name: name, destination_namespace: namespace }) {
      return [namespace, name].filter(Boolean).join('/');
    },

    getFullDestinationUrl(params) {
      return joinPaths(gon.relative_url_root || '', '/', this.getDestinationUrl(params));
    },
  },

  gitlabLogo: window.gon.gitlab_logo,
  historyPaginationSizePersistKey: HISTORY_PAGINATION_SIZE_PERSIST_KEY,
};
</script>

<template>
  <div>
    <div
      class="gl-border-solid gl-border-gray-200 gl-border-0 gl-border-b-1 gl-display-flex gl-align-items-center"
    >
      <h1 class="gl-my-0 gl-py-4 gl-font-size-h1">
        <img :src="$options.gitlabLogo" class="gl-w-6 gl-h-6 gl-mb-2 gl-display-inline gl-mr-2" />
        {{ s__('BulkImport|Group import history') }}
      </h1>
    </div>
    <gl-loading-icon v-if="loading" size="lg" class="gl-mt-5" />
    <gl-empty-state
      v-else-if="!hasHistoryItems"
      :title="s__('BulkImport|No history is available')"
      :description="s__('BulkImport|Your imported groups will appear here.')"
    />
    <template v-else>
      <gl-table
        :fields="$options.fields"
        :items="historyItems"
        data-qa-selector="import_history_table"
        class="gl-w-full"
      >
        <template #cell(destination_name)="{ item }">
          <gl-link :href="getFullDestinationUrl(item)" target="_blank">
            {{ getDestinationUrl(item) }}
          </gl-link>
        </template>
        <template #cell(created_at)="{ value }">
          <time-ago :time="value" />
        </template>
        <template #cell(status)="{ value, item, toggleDetails, detailsShowing }">
          <import-status :status="value" class="gl-display-inline-block gl-w-13" />
          <gl-button
            v-if="item.failures.length"
            class="gl-ml-3"
            :selected="detailsShowing"
            @click="toggleDetails"
            >{{ __('Details') }}</gl-button
          >
        </template>
        <template #row-details="{ item }">
          <pre><code>{{ item.failures }}</code></pre>
        </template>
      </gl-table>
      <pagination-bar
        :page-info="pageInfo"
        class="gl-m-0 gl-mt-3"
        @set-page="paginationConfig.page = $event"
        @set-page-size="paginationConfig.perPage = $event"
      />
    </template>
    <local-storage-sync
      v-model="paginationConfig.perPage"
      :storage-key="$options.historyPaginationSizePersistKey"
    />
  </div>
</template>
