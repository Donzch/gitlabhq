<script>
import { GlTokenSelector, GlAvatar, GlAvatarLabeled, GlIcon, GlSprintf } from '@gitlab/ui';
import { debounce } from 'lodash';
import { __ } from '~/locale';
import { getUsers } from '~/rest_api';
import { memberName } from '../utils/member_utils';
import { SEARCH_DELAY, USERS_FILTER_ALL, USERS_FILTER_SAML_PROVIDER_ID } from '../constants';

export default {
  components: {
    GlTokenSelector,
    GlAvatar,
    GlAvatarLabeled,
    GlIcon,
    GlSprintf,
  },
  props: {
    placeholder: {
      type: String,
      required: false,
      default: '',
    },
    ariaLabelledby: {
      type: String,
      required: true,
    },
    exceptionState: {
      type: Boolean,
      required: false,
      default: false,
    },
    usersFilter: {
      type: String,
      required: false,
      default: USERS_FILTER_ALL,
    },
    filterId: {
      type: Number,
      required: false,
      default: null,
    },
    invalidMembers: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      query: '',
      users: [],
      selectedTokens: [],
      hasBeenFocused: false,
      hideDropdownWithNoItems: true,
    };
  },
  computed: {
    emailIsValid() {
      const regex = /.+@/;

      return this.query.match(regex) !== null;
    },
    placeholderText() {
      if (this.selectedTokens.length === 0) {
        return this.placeholder;
      }
      return '';
    },
    queryOptions() {
      if (this.usersFilter === USERS_FILTER_SAML_PROVIDER_ID) {
        return {
          saml_provider_id: this.filterId,
          ...this.$options.defaultQueryOptions,
        };
      }
      return this.$options.defaultQueryOptions;
    },
  },
  methods: {
    handleTextInput(query) {
      this.hideDropdownWithNoItems = false;
      this.query = query;
      this.loading = true;
      this.retrieveUsers(query);
    },
    retrieveUsers: debounce(function debouncedRetrieveUsers() {
      return getUsers(this.query, this.queryOptions)
        .then((response) => {
          this.users = response.data.map((token) => ({
            id: token.id,
            name: token.name,
            username: token.username,
            avatar_url: token.avatar_url,
          }));
          this.loading = false;
        })
        .catch(() => {
          this.loading = false;
        });
    }, SEARCH_DELAY),
    handleInput() {
      this.$emit('input', this.selectedTokens);
    },
    handleBlur() {
      this.hideDropdownWithNoItems = false;
    },
    handleFocus() {
      // The modal auto-focuses on the input when opened.
      // This prevents the dropdown from opening when the modal opens.
      if (this.hasBeenFocused) {
        this.loading = true;
        this.retrieveUsers();
      }

      this.hasBeenFocused = true;
    },
    handleTokenRemove(value) {
      if (this.selectedTokens.length) {
        this.$emit('token-remove', value);

        return;
      }

      this.$emit('clear');
    },
    hasError(token) {
      return Object.keys(this.invalidMembers).includes(memberName(token));
    },
  },
  defaultQueryOptions: { without_project_bots: true, active: true },
  i18n: {
    inviteTextMessage: __('Invite "%{email}" by email'),
  },
};
</script>

<template>
  <gl-token-selector
    v-model="selectedTokens"
    :state="exceptionState"
    :dropdown-items="users"
    :loading="loading"
    :allow-user-defined-tokens="emailIsValid"
    :hide-dropdown-with-no-items="hideDropdownWithNoItems"
    :placeholder="placeholderText"
    :aria-labelledby="ariaLabelledby"
    :text-input-attrs="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
      'data-testid': 'members-token-select-input',
      'data-qa-selector': 'members_token_select_input',
    } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
    @blur="handleBlur"
    @text-input="handleTextInput"
    @input="handleInput"
    @focus="handleFocus"
    @token-remove="handleTokenRemove"
  >
    <template #token-content="{ token }">
      <gl-icon
        v-if="hasError(token)"
        name="error"
        :size="16"
        class="gl-mr-2"
        :data-testid="`error-icon-${token.id}`"
      />
      <gl-avatar
        v-else-if="token.avatar_url"
        :src="token.avatar_url"
        :size="16"
        data-testid="token-avatar"
      />
      {{ token.name }}
    </template>

    <template #dropdown-item-content="{ dropdownItem }">
      <gl-avatar-labeled
        :src="dropdownItem.avatar_url"
        :size="32"
        :label="dropdownItem.name"
        :sub-label="dropdownItem.username"
      />
    </template>

    <template #user-defined-token-content="{ inputText: email }">
      <gl-sprintf :message="$options.i18n.inviteTextMessage">
        <template #email>
          <span>{{ email }}</span>
        </template>
      </gl-sprintf>
    </template>
  </gl-token-selector>
</template>
