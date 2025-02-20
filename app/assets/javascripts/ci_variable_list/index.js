import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import CiVariableSettings from './components/ci_variable_settings.vue';
import LegacyCiVariableSettings from './components/legacy_ci_variable_settings.vue';
import createStore from './store';

const mountCiVariableListApp = (containerEl) => {
  const {
    awsLogoSvgPath,
    awsTipCommandsLink,
    awsTipDeployLink,
    awsTipLearnLink,
    containsVariableReferenceLink,
    environmentScopeLink,
    group,
    maskedEnvironmentVariablesLink,
    maskableRegex,
    projectFullPath,
    projectId,
    protectedByDefault,
    protectedEnvironmentVariablesLink,
  } = containerEl.dataset;

  const isGroup = parseBoolean(group);
  const isProtectedByDefault = parseBoolean(protectedByDefault);

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      awsLogoSvgPath,
      awsTipCommandsLink,
      awsTipDeployLink,
      awsTipLearnLink,
      containsVariableReferenceLink,
      environmentScopeLink,
      isGroup,
      isProtectedByDefault,
      maskedEnvironmentVariablesLink,
      maskableRegex,
      projectFullPath,
      projectId,
      protectedEnvironmentVariablesLink,
    },
    render(createElement) {
      return createElement(CiVariableSettings);
    },
  });
};

const mountLegacyCiVariableListApp = (containerEl) => {
  const {
    endpoint,
    projectId,
    group,
    maskableRegex,
    protectedByDefault,
    awsLogoSvgPath,
    awsTipDeployLink,
    awsTipCommandsLink,
    awsTipLearnLink,
    containsVariableReferenceLink,
    protectedEnvironmentVariablesLink,
    maskedEnvironmentVariablesLink,
    environmentScopeLink,
  } = containerEl.dataset;
  const isGroup = parseBoolean(group);
  const isProtectedByDefault = parseBoolean(protectedByDefault);

  const store = createStore({
    endpoint,
    projectId,
    isGroup,
    maskableRegex,
    isProtectedByDefault,
    awsLogoSvgPath,
    awsTipDeployLink,
    awsTipCommandsLink,
    awsTipLearnLink,
    containsVariableReferenceLink,
    protectedEnvironmentVariablesLink,
    maskedEnvironmentVariablesLink,
    environmentScopeLink,
  });

  return new Vue({
    el: containerEl,
    store,
    render(createElement) {
      return createElement(LegacyCiVariableSettings);
    },
  });
};

export default (containerId = 'js-ci-project-variables') => {
  const el = document.getElementById(containerId);

  if (el) {
    if (gon.features?.ciVariableSettingsGraphql) {
      mountCiVariableListApp(el);
    } else {
      mountLegacyCiVariableListApp(el);
    }
  }
};
