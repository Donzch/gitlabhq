<script>
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { mapGetters, mapState, mapActions } from 'vuex';
import { IdState } from 'vendor/vue-virtual-scroller';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import draftCommentsMixin from '~/diffs/mixins/draft_comments';
import { getCommentedLines } from '~/notes/components/multiline_comment_utils';
import { hide } from '~/tooltips';
import { pickDirection } from '../utils/diff_line';
import DiffCommentCell from './diff_comment_cell.vue';
import DiffCodeQuality from './diff_code_quality.vue';
import DiffExpansionCell from './diff_expansion_cell.vue';
import DiffRow from './diff_row.vue';
import { isHighlighted } from './diff_row_utils';

export default {
  components: {
    DiffExpansionCell,
    DiffRow,
    DiffCommentCell,
    DiffCodeQuality,
    DraftNote,
  },
  directives: {
    SafeHtml,
  },
  mixins: [
    draftCommentsMixin,
    IdState({ idProp: (vm) => vm.diffFile.file_hash }),
    glFeatureFlagsMixin(),
  ],
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
    diffLines: {
      type: Array,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    inline: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      codeQualityExpandedLines: [],
    };
  },
  idState() {
    return {
      dragStart: null,
      updatedLineRange: null,
    };
  },
  computed: {
    ...mapGetters('diffs', ['commitId', 'fileLineCoverage']),
    ...mapState('diffs', ['codequalityDiff', 'highlightedRow', 'coverageLoaded']),
    ...mapState({
      selectedCommentPosition: ({ notes }) => notes.selectedCommentPosition,
      selectedCommentPositionHover: ({ notes }) => notes.selectedCommentPositionHover,
    }),
    diffLinesLength() {
      return this.diffLines.length;
    },
    commentedLines() {
      return getCommentedLines(
        this.selectedCommentPosition || this.selectedCommentPositionHover,
        this.diffLines,
      );
    },
    hasCodequalityChanges() {
      return this.codequalityDiff?.files?.[this.diffFile.file_path]?.length > 0;
    },
  },
  methods: {
    ...mapActions(['setSelectedCommentPosition']),
    ...mapActions('diffs', ['showCommentForm', 'setHighlightedRow', 'toggleLineDiscussions']),
    showCommentLeft(line) {
      return line.left && !line.right;
    },
    showCommentRight(line) {
      return line.right && !line.left;
    },
    onStartDragging({ event = {}, line }) {
      if (event.target?.parentNode) {
        hide(event.target.parentNode);
      }
      this.idState.dragStart = line;
    },
    parseCodeQuality(line) {
      return (line.left ?? line.right)?.codequality;
    },

    hideCodeQualityFindings(line) {
      const index = this.codeQualityExpandedLines.indexOf(line);
      if (index > -1) {
        this.codeQualityExpandedLines.splice(index, 1);
      }
    },
    toggleCodeQualityFindings(line) {
      if (!this.codeQualityExpandedLines.includes(line)) {
        this.codeQualityExpandedLines.push(line);
      } else {
        this.hideCodeQualityFindings(line);
      }
    },
    onDragOver(line) {
      if (line.chunk !== this.idState.dragStart.chunk) return;

      let start = this.idState.dragStart;
      let end = line;

      if (this.idState.dragStart.index >= line.index) {
        start = line;
        end = this.idState.dragStart;
      }

      this.idState.updatedLineRange = { start, end };

      this.setSelectedCommentPosition(this.idState.updatedLineRange);
    },
    onStopDragging() {
      this.showCommentForm({
        lineCode: this.idState.updatedLineRange?.end?.line_code,
        fileHash: this.diffFile.file_hash,
      });
      this.idState.dragStart = null;
    },
    singleLineComment(code, line) {
      const lineDir = pickDirection({ line, code });

      this.idState.updatedLineRange = {
        start: lineDir,
        end: lineDir,
      };

      this.showCommentForm({ lineCode: lineDir.line_code, fileHash: this.diffFile.file_hash });
    },
    isHighlighted(line) {
      return isHighlighted(
        this.highlightedRow,
        line.left?.line_code ? line.left : line.right,
        false,
      );
    },
    handleParallelLineMouseDown(e) {
      const line = e.target.closest('.diff-td');
      if (line) {
        const table = line.closest('.diff-table');
        table.classList.remove('left-side-selected', 'right-side-selected');
        const [lineClass] = ['left-side', 'right-side'].filter((name) =>
          line.classList.contains(name),
        );

        if (lineClass) {
          table.classList.add(`${lineClass}-selected`);
        }
      }
    },
    getCountBetweenIndex(index) {
      if (index === 0) {
        return -1;
      } else if (!this.diffLines[index + 1]) {
        return -1;
      }

      return (
        Number(this.diffLines[index + 1].left.new_line) -
        Number(this.diffLines[index - 1].left.new_line)
      );
    },
    getCodeQualityLine(line) {
      return this.parseCodeQuality(line)?.[0]?.line;
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <div
    :class="[
      $options.userColorScheme,
      { 'inline-diff-view': inline, 'with-codequality': hasCodequalityChanges },
    ]"
    :data-commit-id="commitId"
    class="diff-grid diff-table code diff-wrap-lines js-syntax-highlight text-file"
    @mousedown="handleParallelLineMouseDown"
  >
    <template v-for="(line, index) in diffLines">
      <template v-if="line.isMatchLineLeft || line.isMatchLineRight">
        <diff-expansion-cell
          :key="`expand-${index}`"
          :file="diffFile"
          :line="line.left"
          :is-top="index === 0"
          :is-bottom="index + 1 === diffLinesLength"
          :inline="inline"
          :line-count-between="getCountBetweenIndex(index)"
        />
      </template>
      <diff-row
        v-if="!line.isMatchLineLeft && !line.isMatchLineRight"
        :key="line.line_code"
        :file-hash="diffFile.file_hash"
        :file-path="diffFile.file_path"
        :line="line"
        :is-bottom="index + 1 === diffLinesLength"
        :is-commented="index >= commentedLines.startLine && index <= commentedLines.endLine"
        :inline="inline"
        :index="index"
        :is-highlighted="isHighlighted(line)"
        :file-line-coverage="fileLineCoverage"
        :coverage-loaded="coverageLoaded"
        @showCommentForm="(code) => singleLineComment(code, line)"
        @setHighlightedRow="setHighlightedRow"
        @toggleCodeQualityFindings="toggleCodeQualityFindings"
        @toggleLineDiscussions="
          ({ lineCode, expanded }) =>
            toggleLineDiscussions({ lineCode, fileHash: diffFile.file_hash, expanded })
        "
        @enterdragging="onDragOver"
        @startdragging="onStartDragging"
        @stopdragging="onStopDragging"
      />

      <diff-code-quality
        v-if="
          glFeatures.refactorCodeQualityInlineFindings &&
          codeQualityExpandedLines.includes(getCodeQualityLine(line))
        "
        :key="line.line_code"
        :line="getCodeQualityLine(line)"
        :code-quality="parseCodeQuality(line)"
        @hideCodeQualityFindings="hideCodeQualityFindings"
      />
      <div
        v-if="line.renderCommentRow"
        :key="`dcr-${line.line_code || index}`"
        :class="line.commentRowClasses"
        class="diff-grid-comments diff-tr notes_holder"
      >
        <div
          v-if="line.left || !inline"
          :class="{ parallel: !inline }"
          class="diff-td notes-content old"
        >
          <diff-comment-cell
            v-if="line.left && (line.left.renderDiscussion || line.left.hasCommentForm)"
            :line="line.left"
            :line-range="idState.updatedLineRange"
            :diff-file-hash="diffFile.file_hash"
            :help-page-path="helpPagePath"
            line-position="left"
          />
        </div>
        <div
          v-if="line.right || !inline"
          :class="{ parallel: !inline }"
          class="diff-td notes-content new"
        >
          <diff-comment-cell
            v-if="line.right && (line.right.renderDiscussion || line.right.hasCommentForm)"
            :line="line.right"
            :line-range="idState.updatedLineRange"
            :diff-file-hash="diffFile.file_hash"
            :line-index="index"
            :help-page-path="helpPagePath"
            line-position="right"
          />
        </div>
      </div>
      <div
        v-if="shouldRenderParallelDraftRow(diffFile.file_hash, line)"
        :key="`drafts-${index}`"
        :class="line.draftRowClasses"
        class="diff-grid-drafts diff-tr notes_holder"
      >
        <div
          v-if="!inline || (line.left && line.left.lineDraft.isDraft)"
          class="diff-td notes-content parallel old"
        >
          <div v-if="line.left && line.left.lineDraft.isDraft" class="content">
            <draft-note :draft="line.left.lineDraft" :line="line.left" />
          </div>
        </div>
        <div
          v-if="!inline || (line.right && line.right.lineDraft.isDraft)"
          class="diff-td notes-content parallel new"
        >
          <div v-if="line.right && line.right.lineDraft.isDraft" class="content">
            <draft-note :draft="line.right.lineDraft" :line="line.right" />
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
