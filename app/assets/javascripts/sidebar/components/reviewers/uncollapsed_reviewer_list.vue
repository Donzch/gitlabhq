<script>
import { GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __, sprintf, s__ } from '~/locale';
import AttentionRequestedToggle from '../attention_requested_toggle.vue';
import ReviewerAvatarLink from './reviewer_avatar_link.vue';

const LOADING_STATE = 'loading';
const SUCCESS_STATE = 'success';

export default {
  i18n: {
    reRequestReview: __('Re-request review'),
  },
  components: {
    GlButton,
    GlIcon,
    ReviewerAvatarLink,
    AttentionRequestedToggle,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    users: {
      type: Array,
      required: true,
    },
    rootPath: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
  },
  data() {
    return {
      showLess: true,
      loadingStates: {},
    };
  },
  watch: {
    users: {
      handler(users) {
        this.loadingStates = users.reduce(
          (acc, user) => ({
            ...acc,
            [user.id]: acc[user.id] || null,
          }),
          this.loadingStates,
        );
      },
      immediate: true,
    },
  },
  methods: {
    approvedByTooltipTitle(user) {
      return sprintf(s__('MergeRequest|Approved by @%{username}'), user);
    },
    toggleShowLess() {
      this.showLess = !this.showLess;
    },
    reRequestReview(userId) {
      this.loadingStates[userId] = LOADING_STATE;
      this.$emit('request-review', { userId, callback: this.requestReviewComplete });
    },

    requestReviewComplete(userId, success) {
      if (success) {
        this.loadingStates[userId] = SUCCESS_STATE;

        setTimeout(() => {
          this.loadingStates[userId] = null;
        }, 1500);
      } else {
        this.loadingStates[userId] = null;
      }
    },
    toggleAttentionRequested(data) {
      this.$emit('toggle-attention-requested', data);
    },
  },
  LOADING_STATE,
  SUCCESS_STATE,
};
</script>

<template>
  <div>
    <div
      v-for="(user, index) in users"
      :key="user.id"
      :class="{
        'gl-mb-3': index !== users.length - 1,
        'attention-requests': glFeatures.mrAttentionRequests,
      }"
      class="gl-display-grid gl-align-items-center reviewer-grid gl-mr-2"
      data-testid="reviewer"
    >
      <reviewer-avatar-link
        :user="user"
        :root-path="rootPath"
        :issuable-type="issuableType"
        class="gl-word-break-word gl-mr-2"
        data-css-area="user"
      >
        <div class="gl-ml-3 gl-line-height-normal gl-display-grid gl-align-items-center">
          {{ user.name }}
        </div>
      </reviewer-avatar-link>
      <attention-requested-toggle
        v-if="glFeatures.mrAttentionRequests"
        :user="user"
        type="reviewer"
        class="gl-mr-2"
        data-css-area="attention"
        @toggle-attention-requested="toggleAttentionRequested"
      />
      <gl-icon
        v-if="user.approved"
        v-gl-tooltip.left
        :size="16"
        :title="approvedByTooltipTitle(user)"
        name="status-success"
        class="float-right gl-my-2 gl-ml-auto gl-text-green-500 gl-flex-shrink-0"
        data-testid="re-approved"
      />
      <gl-icon
        v-if="loadingStates[user.id] === $options.SUCCESS_STATE"
        :size="24"
        name="check"
        class="float-right gl-py-2 gl-mr-2 gl-text-green-500"
        data-testid="re-request-success"
      />
      <gl-button
        v-else-if="
          user.can_update_merge_request && user.reviewed && !glFeatures.mrAttentionRequests
        "
        v-gl-tooltip.left
        :title="$options.i18n.reRequestReview"
        :aria-label="$options.i18n.reRequestReview"
        :loading="loadingStates[user.id] === $options.LOADING_STATE"
        class="float-right gl-text-gray-500!"
        size="small"
        icon="redo"
        variant="link"
        data-testid="re-request-button"
        @click="reRequestReview(user.id)"
      />
    </div>
  </div>
</template>
