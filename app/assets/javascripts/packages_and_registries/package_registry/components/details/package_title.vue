<script>
import { GlSprintf, GlBadge, GlResizeObserverDirective } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __ } from '~/locale';
import PackageTags from '~/packages_and_registries/shared/components/package_tags.vue';
import { PACKAGE_TYPE_NUGET } from '~/packages_and_registries/package_registry/constants';
import { getPackageTypeLabel } from '~/packages_and_registries/package_registry/utils';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'PackageTitle',
  components: {
    TitleArea,
    GlSprintf,
    PackageTags,
    MetadataItem,
    GlBadge,
    TimeAgoTooltip,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  i18n: {
    packageInfo: __('v%{version} published %{timeAgo}'),
  },
  props: {
    packageEntity: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isDesktop: true,
    };
  },
  computed: {
    packageTypeDisplay() {
      return getPackageTypeLabel(this.packageEntity.packageType);
    },
    packagePipeline() {
      return this.packageEntity.pipelines?.nodes[0];
    },
    packageIcon() {
      if (this.packageEntity.packageType === PACKAGE_TYPE_NUGET) {
        return this.packageEntity.metadata?.iconUrl || null;
      }
      return null;
    },
    hasTagsToDisplay() {
      return Boolean(this.packageEntity.tags?.nodes && this.packageEntity.tags?.nodes.length);
    },
    totalSize() {
      return this.packageEntity.packageFiles
        ? numberToHumanSize(
            this.packageEntity.packageFiles.nodes.reduce((acc, p) => acc + Number(p.size), 0),
          )
        : '0';
    },
  },
  mounted() {
    this.checkBreakpoints();
  },
  methods: {
    dynamicSlotName(index) {
      return `metadata-tag${index}`;
    },
    checkBreakpoints() {
      this.isDesktop = GlBreakpointInstance.isDesktop();
    },
  },
};
</script>

<template>
  <title-area
    v-gl-resize-observer="checkBreakpoints"
    :title="packageEntity.name"
    :avatar="packageIcon"
    data-qa-selector="package_title"
  >
    <template #sub-header>
      <span data-testid="sub-header">
        <gl-sprintf :message="$options.i18n.packageInfo">
          <template #version>
            {{ packageEntity.version }}
          </template>

          <template #timeAgo>
            <time-ago-tooltip
              v-if="packageEntity.createdAt"
              class="gl-ml-2"
              :time="packageEntity.createdAt"
            />
          </template>
        </gl-sprintf>
      </span>
    </template>

    <template v-if="packageTypeDisplay" #metadata-type>
      <metadata-item data-testid="package-type" icon="package" :text="packageTypeDisplay" />
    </template>

    <template #metadata-size>
      <metadata-item data-testid="package-size" icon="disk" :text="totalSize" />
    </template>

    <template v-if="packagePipeline" #metadata-pipeline>
      <metadata-item
        data-testid="pipeline-project"
        icon="review-list"
        :text="packagePipeline.project.name"
        :link="packagePipeline.project.webUrl"
      />
    </template>

    <template v-if="packagePipeline && packagePipeline.ref" #metadata-ref>
      <metadata-item data-testid="package-ref" icon="branch" :text="packagePipeline.ref" />
    </template>

    <template v-if="isDesktop && hasTagsToDisplay" #metadata-tags>
      <package-tags :tag-display-limit="2" :tags="packageEntity.tags.nodes" hide-label />
    </template>

    <!-- we need to duplicate the package tags on mobile to ensure proper styling inside the flex wrap -->
    <template
      v-for="(tag, index) in packageEntity.tags.nodes"
      v-else-if="hasTagsToDisplay"
      #[dynamicSlotName(index)]
    >
      <gl-badge :key="index" class="gl-my-1" data-testid="tag-badge" variant="info" size="sm">
        {{ tag.name }}
      </gl-badge>
    </template>

    <template #right-actions>
      <slot name="delete-button"></slot>
    </template>
  </title-area>
</template>
