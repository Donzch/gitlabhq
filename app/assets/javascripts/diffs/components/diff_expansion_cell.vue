<script>
import { GlTooltipDirective, GlSafeHtmlDirective, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { mapActions } from 'vuex';
import createFlash from '~/flash';
import { s__, sprintf } from '~/locale';
import { UNFOLD_COUNT, INLINE_DIFF_LINES_KEY } from '../constants';
import * as utils from '../store/utils';

const EXPAND_ALL = 0;
const EXPAND_UP = 1;
const EXPAND_DOWN = 2;

export default {
  i18n: {
    showMore: sprintf(s__('Diffs|Show %{unfoldCount} lines'), { unfoldCount: UNFOLD_COUNT }),
    showAll: s__('Diffs|Show all unchanged lines'),
  },
  components: {
    GlIcon,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    file: {
      type: Object,
      required: true,
    },
    line: {
      type: Object,
      required: true,
    },
    isTop: {
      type: Boolean,
      required: false,
      default: false,
    },
    isBottom: {
      type: Boolean,
      required: false,
      default: false,
    },
    inline: {
      type: Boolean,
      required: true,
    },
    lineCountBetween: {
      type: Number,
      required: false,
      default: -1,
    },
  },
  data() {
    return { loading: { up: false, down: false, all: false } };
  },
  computed: {
    canExpandUp() {
      return !this.isBottom;
    },
    canExpandDown() {
      return this.isBottom || !this.isTop;
    },
    isLineCountSmall() {
      return this.lineCountBetween >= 20 || this.lineCountBetween === -1;
    },
    showExpandDown() {
      return this.canExpandDown && this.isLineCountSmall;
    },
    showExpandUp() {
      return this.canExpandUp && this.isLineCountSmall;
    },
  },
  methods: {
    ...mapActions('diffs', ['loadMoreLines']),
    getPrevLineNumber(oldLineNumber, newLineNumber) {
      const index = utils.getPreviousLineIndex(this.file, {
        oldLineNumber,
        newLineNumber,
      });

      return this.file[INLINE_DIFF_LINES_KEY][index - 2]?.new_line || 0;
    },
    callLoadMoreLines(
      endpoint,
      params,
      lineNumbers,
      fileHash,
      isExpandDown = false,
      nextLineNumbers = {},
    ) {
      this.loadMoreLines({ endpoint, params, lineNumbers, fileHash, isExpandDown, nextLineNumbers })
        .catch(() => {
          createFlash({
            message: s__('Diffs|Something went wrong while fetching diff lines.'),
          });
        })
        .finally(() => {
          this.loading = { up: false, down: false, all: false };
        });
    },
    handleExpandLines(type = EXPAND_ALL) {
      const endpoint = this.file.context_lines_path;
      const oldLineNumber = this.line.meta_data.old_pos || 0;
      const newLineNumber = this.line.meta_data.new_pos || 0;
      const offset = newLineNumber - oldLineNumber;

      const expandOptions = { endpoint, oldLineNumber, newLineNumber, offset };

      if (type === EXPAND_UP) {
        this.loading.up = true;
        this.handleExpandUpLines(expandOptions);
      } else if (type === EXPAND_DOWN) {
        this.loading.down = true;
        this.handleExpandDownLines(expandOptions);
      } else {
        this.loading.all = true;
        this.handleExpandAllLines(expandOptions);
      }
    },
    handleExpandUpLines(expandOptions) {
      const { endpoint, oldLineNumber, newLineNumber, offset } = expandOptions;

      const bottom = this.isBottom;
      const lineNumber = newLineNumber - 1;
      const to = lineNumber;
      let since = lineNumber - UNFOLD_COUNT;
      let unfold = true;

      const prevLineNumber = this.getPrevLineNumber(oldLineNumber, newLineNumber);
      if (since <= prevLineNumber + 1) {
        since = prevLineNumber + 1;
        unfold = false;
      }

      const params = { since, to, bottom, offset, unfold };
      const lineNumbers = { oldLineNumber, newLineNumber };
      this.callLoadMoreLines(endpoint, params, lineNumbers, this.file.file_hash);
    },
    handleExpandDownLines(expandOptions) {
      const {
        endpoint,
        oldLineNumber: metaOldPos,
        newLineNumber: metaNewPos,
        offset,
      } = expandOptions;

      const bottom = true;
      const nextLineNumbers = {
        old_line: metaOldPos,
        new_line: metaNewPos,
      };

      let unfold = true;
      let isExpandDown = false;
      let oldLineNumber = metaOldPos;
      let newLineNumber = metaNewPos;
      let lineNumber = metaNewPos + 1;
      let since = lineNumber;
      let to = lineNumber + UNFOLD_COUNT;

      if (!this.isBottom) {
        const prevLineNumber = this.getPrevLineNumber(oldLineNumber, newLineNumber);

        isExpandDown = true;
        oldLineNumber = prevLineNumber - offset;
        newLineNumber = prevLineNumber;
        lineNumber = prevLineNumber + 1;
        since = lineNumber;
        to = lineNumber + UNFOLD_COUNT;

        if (to >= metaNewPos) {
          to = metaNewPos - 1;
          unfold = false;
        }
      }

      const params = { since, to, bottom, offset, unfold };
      const lineNumbers = { oldLineNumber, newLineNumber };
      this.callLoadMoreLines(
        endpoint,
        params,
        lineNumbers,
        this.file.file_hash,
        isExpandDown,
        nextLineNumbers,
      );
    },
    handleExpandAllLines(expandOptions) {
      const { endpoint, oldLineNumber, newLineNumber, offset } = expandOptions;
      const bottom = this.isBottom;
      const unfold = false;
      let since;
      let to;

      if (this.isTop) {
        since = 1;
        to = newLineNumber - 1;
      } else if (bottom) {
        since = newLineNumber + 1;
        to = -1;
      } else {
        const prevLineNumber = this.getPrevLineNumber(oldLineNumber, newLineNumber);
        since = prevLineNumber + 1;
        to = newLineNumber - 1;
      }

      const params = { since, to, bottom, offset, unfold };
      const lineNumbers = { oldLineNumber, newLineNumber };
      this.callLoadMoreLines(endpoint, params, lineNumbers, this.file.file_hash);
    },
  },
  EXPAND_DOWN,
  EXPAND_UP,
};
</script>

<template>
  <div class="diff-grid-row diff-grid-row-full diff-tr line_holder match expansion">
    <div :class="{ parallel: !inline }" class="diff-grid-left diff-grid-2-col left-side">
      <div
        class="diff-td diff-line-num gl-text-center! gl-p-0! gl-w-full! gl-display-flex gl-flex-direction-column"
      >
        <button
          v-if="showExpandDown"
          v-gl-tooltip.left
          :title="s__('Diffs|Next 20 lines')"
          :disabled="loading.down"
          type="button"
          class="js-unfold-down gl-rounded-0 gl-border-0 diff-line-expand-button"
          @click="handleExpandLines($options.EXPAND_DOWN)"
        >
          <gl-loading-icon v-if="loading.down" size="sm" color="dark" inline />
          <gl-icon v-else name="expand-down" />
        </button>
        <button
          v-if="lineCountBetween !== -1 && lineCountBetween < 20"
          v-gl-tooltip.left
          :title="s__('Diffs|Expand all lines')"
          :disabled="loading.all"
          type="button"
          class="js-unfold-all gl-rounded-0 gl-border-0 diff-line-expand-button"
          @click="handleExpandLines()"
        >
          <gl-loading-icon v-if="loading.all" size="sm" color="dark" inline />
          <gl-icon v-else name="expand" />
        </button>
        <button
          v-if="showExpandUp"
          v-gl-tooltip.left
          :title="s__('Diffs|Previous 20 lines')"
          :disabled="loading.up"
          type="button"
          class="js-unfold gl-rounded-0 gl-border-0 diff-line-expand-button"
          @click="handleExpandLines($options.EXPAND_UP)"
        >
          <gl-loading-icon v-if="loading.up" size="sm" color="dark" inline />
          <gl-icon v-else name="expand-up" />
        </button>
      </div>
      <div
        v-safe-html="line.rich_text"
        class="gl-display-flex! gl-flex-direction-column gl-justify-content-center diff-td line_content left-side gl-white-space-normal!"
      ></div>
    </div>
  </div>
</template>
