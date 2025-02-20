<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import createTestReportsStore from '../../stores/test_reports';
import EmptyState from './empty_state.vue';
import TestSuiteTable from './test_suite_table.vue';
import TestSummary from './test_summary.vue';
import TestSummaryTable from './test_summary_table.vue';

export default {
  name: 'TestReports',
  components: {
    EmptyState,
    GlLoadingIcon,
    TestSuiteTable,
    TestSummary,
    TestSummaryTable,
  },
  inject: ['blobPath', 'summaryEndpoint', 'suiteEndpoint'],
  computed: {
    ...mapState('testReports', ['isLoading', 'selectedSuiteIndex', 'testReports']),
    ...mapGetters('testReports', ['getSelectedSuite']),
    showSuite() {
      return this.selectedSuiteIndex !== null;
    },
    showTests() {
      const { test_suites: testSuites = [] } = this.testReports;
      return testSuites.length > 0;
    },
  },
  created() {
    this.$store.registerModule(
      'testReports',
      createTestReportsStore({
        blobPath: this.blobPath,
        summaryEndpoint: this.summaryEndpoint,
        suiteEndpoint: this.suiteEndpoint,
      }),
    );

    this.fetchSummary();
  },
  methods: {
    ...mapActions('testReports', [
      'fetchTestSuite',
      'fetchSummary',
      'setSelectedSuiteIndex',
      'removeSelectedSuiteIndex',
    ]),
    summaryBackClick() {
      this.removeSelectedSuiteIndex();
    },
    summaryTableRowClick(index) {
      this.setSelectedSuiteIndex(index);

      // Fetch the test suite when the user clicks to see more details
      this.fetchTestSuite(index);
    },
    beforeEnterTransition() {
      document.documentElement.style.overflowX = 'hidden';
    },
    afterLeaveTransition() {
      document.documentElement.style.overflowX = '';
    },
  },
};
</script>

<template>
  <div v-if="isLoading">
    <gl-loading-icon size="lg" class="gl-mt-3" />
  </div>

  <div
    v-else-if="!isLoading && showTests"
    ref="container"
    class="position-relative"
    data-testid="tests-detail"
  >
    <transition
      name="slide"
      @before-enter="beforeEnterTransition"
      @after-leave="afterLeaveTransition"
    >
      <div v-if="showSuite" key="detail" class="w-100 slide-enter-to-element">
        <test-summary :report="getSelectedSuite" show-back @on-back-click="summaryBackClick" />

        <test-suite-table />
      </div>

      <div v-else key="summary" class="w-100 slide-enter-from-element">
        <test-summary :report="testReports" />

        <test-summary-table @row-click="summaryTableRowClick" />
      </div>
    </transition>
  </div>

  <empty-state v-else />
</template>
