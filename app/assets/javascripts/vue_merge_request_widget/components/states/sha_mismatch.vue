<script>
import { GlButton } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { I18N_SHA_MISMATCH } from '../../i18n';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'ShaMismatch',
  components: {
    statusIcon,
    GlButton,
  },
  i18n: {
    I18N_SHA_MISMATCH,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="false" status="warning" />
    <div class="media-body">
      <span
        :class="{ 'gl-ml-0! gl-text-body!': glFeatures.restructuredMrWidget }"
        class="gl-font-weight-bold"
        data-qa-selector="head_mismatch_content"
      >
        {{ $options.i18n.I18N_SHA_MISMATCH.warningMessage }}
      </span>
      <gl-button
        class="gl-ml-3"
        data-testid="action-button"
        size="small"
        category="primary"
        variant="confirm"
        :href="mr.mergeRequestDiffsPath"
        >{{ $options.i18n.I18N_SHA_MISMATCH.actionButtonLabel }}</gl-button
      >
    </div>
  </div>
</template>
