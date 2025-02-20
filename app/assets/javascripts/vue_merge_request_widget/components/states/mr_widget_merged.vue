<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlLoadingIcon, GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import api from '~/api';
import createFlash from '~/flash';
import { s__, __ } from '~/locale';
import { OPEN_REVERT_MODAL, OPEN_CHERRY_PICK_MODAL } from '~/projects/commit/constants';
import modalEventHub from '~/projects/commit/event_hub';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import eventHub from '../../event_hub';
import MrWidgetAuthorTime from '../mr_widget_author_time.vue';

export default {
  name: 'MRWidgetMerged',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    MrWidgetAuthorTime,
    GlIcon,
    ClipboardButton,
    GlLoadingIcon,
    GlButton,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isMakingRequest: false,
    };
  },
  computed: {
    shouldShowRemoveSourceBranch() {
      const { sourceBranchRemoved, isRemovingSourceBranch, canRemoveSourceBranch } = this.mr;

      return (
        !sourceBranchRemoved &&
        canRemoveSourceBranch &&
        !this.isMakingRequest &&
        !isRemovingSourceBranch
      );
    },
    shouldShowSourceBranchRemoving() {
      const { sourceBranchRemoved, isRemovingSourceBranch } = this.mr;
      return !sourceBranchRemoved && (isRemovingSourceBranch || this.isMakingRequest);
    },
    shouldShowMergedButtons() {
      const {
        canRevertInCurrentMR,
        canCherryPickInCurrentMR,
        revertInForkPath,
        cherryPickInForkPath,
      } = this.mr;

      return (
        canRevertInCurrentMR || canCherryPickInCurrentMR || revertInForkPath || cherryPickInForkPath
      );
    },
    revertTitle() {
      return s__('mrWidget|Revert this merge request in a new merge request');
    },
    cherryPickTitle() {
      return s__('mrWidget|Cherry-pick this merge request in a new merge request');
    },
    revertLabel() {
      return s__('mrWidget|Revert');
    },
    cherryPickLabel() {
      return s__('mrWidget|Cherry-pick');
    },
  },
  mounted() {
    document.dispatchEvent(new CustomEvent('merged:UpdateActions'));
  },
  methods: {
    removeSourceBranch() {
      this.isMakingRequest = true;

      api.trackRedisHllUserEvent('i_code_review_post_merge_delete_branch');

      this.service
        .removeSourceBranch()
        .then((res) => res.data)
        .then((data) => {
          // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
          // eslint-disable-next-line @gitlab/require-i18n-strings
          if (data.message === 'Branch was deleted') {
            eventHub.$emit('MRWidgetUpdateRequested', () => {
              this.isMakingRequest = false;
            });
          }
        })
        .catch(() => {
          this.isMakingRequest = false;
          createFlash({
            message: __('Something went wrong. Please try again.'),
          });
        });
    },
    openRevertModal() {
      api.trackRedisHllUserEvent('i_code_review_post_merge_click_revert');

      modalEventHub.$emit(OPEN_REVERT_MODAL);
    },
    openCherryPickModal() {
      api.trackRedisHllUserEvent('i_code_review_post_merge_click_cherry_pick');

      modalEventHub.$emit(OPEN_CHERRY_PICK_MODAL);
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <gl-icon name="merge" :size="24" class="gl-text-blue-500 gl-mr-3 gl-mt-1" />
    <div class="media-body">
      <div class="space-children">
        <mr-widget-author-time
          :action-text="s__('mrWidget|Merged by')"
          :author="mr.metrics.mergedBy"
          :date-title="mr.metrics.mergedAt"
          :date-readable="mr.metrics.readableMergedAt"
        />
        <gl-button
          v-if="mr.canRevertInCurrentMR"
          v-gl-tooltip.hover
          :title="revertTitle"
          size="small"
          category="secondary"
          data-qa-selector="revert_button"
          @click="openRevertModal"
        >
          {{ revertLabel }}
        </gl-button>
        <gl-button
          v-else-if="mr.revertInForkPath"
          v-gl-tooltip.hover
          :href="mr.revertInForkPath"
          :title="revertTitle"
          size="small"
          category="secondary"
          data-method="post"
        >
          {{ revertLabel }}
        </gl-button>
        <gl-button
          v-if="mr.canCherryPickInCurrentMR"
          v-gl-tooltip.hover
          :title="cherryPickTitle"
          size="small"
          data-qa-selector="cherry_pick_button"
          @click="openCherryPickModal"
        >
          {{ cherryPickLabel }}
        </gl-button>
        <gl-button
          v-else-if="mr.cherryPickInForkPath"
          v-gl-tooltip.hover
          :href="mr.cherryPickInForkPath"
          :title="cherryPickTitle"
          size="small"
          data-method="post"
        >
          {{ cherryPickLabel }}
        </gl-button>
        <gl-button
          v-if="shouldShowRemoveSourceBranch"
          :disabled="isMakingRequest"
          size="small"
          class="js-remove-branch-button"
          @click="removeSourceBranch"
        >
          {{ s__('mrWidget|Delete source branch') }}
        </gl-button>
      </div>
      <section
        v-if="!glFeatures.restructuredMrWidget"
        class="mr-info-list"
        data-qa-selector="merged_status_content"
      >
        <p>
          {{ s__('mrWidget|The changes were merged into') }}
          <span class="label-branch">
            <a :href="mr.targetBranchPath">{{ mr.targetBranch }}</a>
          </span>
          <template v-if="mr.mergeCommitSha">
            with
            <a
              :href="mr.mergeCommitPath"
              class="commit-sha js-mr-merged-commit-sha"
              v-text="mr.shortMergeCommitSha"
            >
            </a>
            <clipboard-button
              :title="__('Copy commit SHA')"
              :text="mr.mergeCommitSha"
              css-class="js-mr-merged-copy-sha"
              category="tertiary"
              size="small"
            />
          </template>
        </p>
        <p v-if="mr.sourceBranchRemoved">
          {{ s__('mrWidget|The source branch has been deleted') }}
        </p>
        <p v-if="shouldShowSourceBranchRemoving">
          <gl-loading-icon size="sm" :inline="true" />
          <span> {{ s__('mrWidget|The source branch is being deleted') }} </span>
        </p>
      </section>
    </div>
  </div>
</template>
