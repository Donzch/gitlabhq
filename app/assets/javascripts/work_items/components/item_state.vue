<script>
import { GlFormGroup, GlFormSelect } from '@gitlab/ui';
import { __ } from '~/locale';
import { STATE_OPEN, STATE_CLOSED } from '../constants';

export default {
  i18n: {
    status: __('Status'),
  },
  states: [
    {
      value: STATE_OPEN,
      text: __('Open'),
    },
    {
      value: STATE_CLOSED,
      text: __('Closed'),
    },
  ],
  components: {
    GlFormGroup,
    GlFormSelect,
  },
  props: {
    state: {
      type: String,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    currentState() {
      return this.$options.states[this.state];
    },
  },
  methods: {
    setState(newState) {
      if (newState !== this.state) {
        this.$emit('changed', newState);
      }
    },
  },
  labelId: 'work-item-state-select',
};
</script>

<template>
  <gl-form-group
    :label="$options.i18n.status"
    :label-for="$options.labelId"
    label-cols="3"
    label-cols-lg="2"
    label-class="gl-pb-0! gl-overflow-wrap-break"
    class="gl-align-items-center"
  >
    <gl-form-select
      :id="$options.labelId"
      :value="state"
      :options="$options.states"
      :disabled="loading"
      class="gl-w-auto hide-select-decoration"
      @change="setState"
    />
  </gl-form-group>
</template>

<style>
.hide-select-decoration:not(:focus, :hover) {
  background-image: none;
  box-shadow: none;
}
</style>
