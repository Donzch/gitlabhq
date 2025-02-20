<script>
import { GlBadge, GlIcon } from '@gitlab/ui';
import Vue from 'vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { fetchPolicies } from '~/lib/graphql';
import { __ } from '~/locale';
import { IssuableType } from '~/issues/constants';
import { IssuableStates } from '~/vue_shared/issuable/list/constants';

export const badgeState = Vue.observable({
  state: '',
  updateStatus: null,
});

const CLASSES = {
  opened: 'issuable-status-badge-open',
  locked: 'issuable-status-badge-open',
  closed: 'issuable-status-badge-closed',
  merged: 'issuable-status-badge-merged',
};

const ISSUE_ICONS = {
  opened: 'issues',
  locked: 'issues',
  closed: 'issue-closed',
};

const MERGE_REQUEST_ICONS = {
  opened: 'merge-request-open',
  locked: 'merge-request-open',
  closed: 'merge-request-close',
  merged: 'merge',
};

const STATUS = {
  opened: __('Open'),
  locked: __('Open'),
  closed: __('Closed'),
  merged: __('Merged'),
};

export default {
  components: {
    GlBadge,
    GlIcon,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    query: { default: null },
    projectPath: { default: null },
    iid: { default: null },
  },
  props: {
    initialState: {
      type: String,
      required: false,
      default: null,
    },
    issuableType: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    if (!this.iid) return { state: this.initialState };

    if (this.initialState) {
      badgeState.state = this.initialState;
    }

    return badgeState;
  },
  computed: {
    badgeClass() {
      return [
        CLASSES[this.state],
        {
          'gl-vertical-align-bottom': this.issuableType === IssuableType.MergeRequest,
        },
      ];
    },
    badgeVariant() {
      if (this.state === IssuableStates.Opened) {
        return 'success';
      } else if (this.state === IssuableStates.Closed) {
        return this.issuableType === IssuableType.MergeRequest ? 'danger' : 'info';
      }
      return 'info';
    },
    badgeText() {
      return STATUS[this.state];
    },
    badgeIcon() {
      if (this.issuableType === IssuableType.Issue) {
        return ISSUE_ICONS[this.state];
      }
      return MERGE_REQUEST_ICONS[this.state];
    },
  },
  created() {
    if (!badgeState.updateStatus) {
      badgeState.updateStatus = this.fetchState;
    }
  },
  beforeDestroy() {
    if (badgeState.updateStatus && this.query) {
      badgeState.updateStatus = null;
    }
  },
  methods: {
    async fetchState() {
      const { data } = await this.$apollo.query({
        query: this.query,
        variables: {
          projectPath: this.projectPath,
          iid: this.iid,
        },
        fetchPolicy: fetchPolicies.NO_CACHE,
      });

      badgeState.state = data?.workspace?.issuable?.state;
    },
  },
};
</script>

<template>
  <gl-badge class="issuable-status-badge gl-mr-3" :class="badgeClass" :variant="badgeVariant">
    <gl-icon :name="badgeIcon" />
    <span class="gl-display-none gl-sm-display-block gl-ml-2">{{ badgeText }}</span>
  </gl-badge>
</template>
