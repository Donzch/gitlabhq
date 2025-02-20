<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { IssuableType } from '~/issues/constants';
import { __, sprintf } from '~/locale';
import AttentionRequestedToggle from '../attention_requested_toggle.vue';
import AssigneeAvatarLink from './assignee_avatar_link.vue';
import UserNameWithStatus from './user_name_with_status.vue';

const DEFAULT_RENDER_COUNT = 5;

export default {
  components: {
    AttentionRequestedToggle,
    AssigneeAvatarLink,
    UserNameWithStatus,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    users: {
      type: Array,
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
    };
  },
  computed: {
    firstUser() {
      return this.users[0];
    },
    hiddenAssigneesLabel() {
      const { numberOfHiddenAssignees } = this;
      return sprintf(__('+ %{numberOfHiddenAssignees} more'), { numberOfHiddenAssignees });
    },
    renderShowMoreSection() {
      return this.users.length > DEFAULT_RENDER_COUNT;
    },
    numberOfHiddenAssignees() {
      return this.users.length - DEFAULT_RENDER_COUNT;
    },
    uncollapsedUsers() {
      if (this.showVerticalList) {
        return this.users;
      }

      const uncollapsedLength = this.showLess
        ? Math.min(this.users.length, DEFAULT_RENDER_COUNT)
        : this.users.length;
      return this.showLess ? this.users.slice(0, uncollapsedLength) : this.users;
    },
    username() {
      return `@${this.firstUser.username}`;
    },
    showVerticalList() {
      return this.glFeatures.mrAttentionRequests && this.isMergeRequest;
    },
    isMergeRequest() {
      return this.issuableType === IssuableType.MergeRequest;
    },
  },
  methods: {
    toggleShowLess() {
      this.showLess = !this.showLess;
    },
    userAvailability(u) {
      if (this.issuableType === IssuableType.MergeRequest) {
        return u?.availability || '';
      }
      return u?.status?.availability || '';
    },
    toggleAttentionRequested(data) {
      this.$emit('toggle-attention-requested', data);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-flex-wrap">
      <div
        v-for="(user, index) in uncollapsedUsers"
        :key="user.id"
        :class="{
          'gl-mb-3': index !== users.length - 1,
        }"
        class="assignee-grid gl-display-grid gl-align-items-center gl-w-full"
      >
        <assignee-avatar-link
          :user="user"
          :issuable-type="issuableType"
          :tooltip-has-name="!showVerticalList"
          class="gl-word-break-word"
          data-css-area="user"
        >
          <div
            class="gl-ml-3 gl-line-height-normal gl-display-grid gl-align-items-center"
            data-testid="username"
          >
            <user-name-with-status :name="user.name" :availability="userAvailability(user)" />
          </div>
        </assignee-avatar-link>
        <attention-requested-toggle
          v-if="showVerticalList"
          :user="user"
          type="assignee"
          class="gl-mr-2"
          data-css-area="attention"
          @toggle-attention-requested="toggleAttentionRequested"
        />
      </div>
    </div>
    <div v-if="renderShowMoreSection" class="user-list-more gl-hover-text-blue-800">
      <button
        type="button"
        class="btn-link gl-button gl-reset-color!"
        data-qa-selector="more_assignees_link"
        @click="toggleShowLess"
      >
        <template v-if="showLess">
          {{ hiddenAssigneesLabel }}
        </template>
        <template v-else>{{ __('- show less') }}</template>
      </button>
    </div>
  </div>
</template>
