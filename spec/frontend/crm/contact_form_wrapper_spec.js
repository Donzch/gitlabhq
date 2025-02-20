import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import ContactFormWrapper from '~/crm/contacts/components/contact_form_wrapper.vue';
import ContactForm from '~/crm/components/form.vue';
import getGroupContactsQuery from '~/crm/contacts/components/graphql/get_group_contacts.query.graphql';
import createContactMutation from '~/crm/contacts/components/graphql/create_contact.mutation.graphql';
import updateContactMutation from '~/crm/contacts/components/graphql/update_contact.mutation.graphql';
import getGroupOrganizationsQuery from '~/crm/organizations/components/graphql/get_group_organizations.query.graphql';
import { getGroupContactsQueryResponse, getGroupOrganizationsQueryResponse } from './mock_data';

describe('Customer relations contact form wrapper', () => {
  Vue.use(VueApollo);
  let wrapper;
  let fakeApollo;

  const findContactForm = () => wrapper.findComponent(ContactForm);

  const $route = {
    params: {
      id: 7,
    },
  };
  const contacts = [{ id: 'gid://gitlab/CustomerRelations::Contact/7' }];

  const mountComponent = ({ isEditMode = false } = {}) => {
    wrapper = shallowMountExtended(ContactFormWrapper, {
      propsData: {
        isEditMode,
      },
      provide: {
        groupFullPath: 'flightjs',
        groupId: 26,
      },
      apolloProvider: fakeApollo,
      mocks: { $route },
    });
  };

  beforeEach(() => {
    fakeApollo = createMockApollo([
      [getGroupContactsQuery, jest.fn().mockResolvedValue(getGroupContactsQueryResponse)],
      [getGroupOrganizationsQuery, jest.fn().mockResolvedValue(getGroupOrganizationsQueryResponse)],
    ]);
  });

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  describe.each`
    mode        | title             | successMessage                 | mutation                 | existingId
    ${'edit'}   | ${'Edit contact'} | ${'Contact has been updated.'} | ${updateContactMutation} | ${contacts[0].id}
    ${'create'} | ${'New contact'}  | ${'Contact has been added.'}   | ${createContactMutation} | ${null}
  `('in $mode mode', ({ mode, title, successMessage, mutation, existingId }) => {
    beforeEach(() => {
      const isEditMode = mode === 'edit';
      mountComponent({ isEditMode });

      return waitForPromises();
    });

    it('renders correct getQuery prop', () => {
      expect(findContactForm().props('getQueryNodePath')).toBe('group.contacts');
    });

    it('renders correct mutation prop', () => {
      expect(findContactForm().props('mutation')).toBe(mutation);
    });

    it('renders correct additionalCreateParams prop', () => {
      expect(findContactForm().props('additionalCreateParams')).toMatchObject({
        groupId: 'gid://gitlab/Group/26',
      });
    });

    it('renders correct existingId prop', () => {
      expect(findContactForm().props('existingId')).toBe(existingId);
    });

    it('renders correct fields prop', () => {
      expect(findContactForm().props('fields')).toEqual([
        { name: 'firstName', label: 'First name', required: true },
        { name: 'lastName', label: 'Last name', required: true },
        { name: 'email', label: 'Email', required: true },
        { name: 'phone', label: 'Phone' },
        {
          name: 'organizationId',
          label: 'Organization',
          values: [
            { text: 'No organization', value: null },
            { text: 'ABC Company', value: 'gid://gitlab/CustomerRelations::Organization/2' },
            { text: 'GitLab', value: 'gid://gitlab/CustomerRelations::Organization/3' },
            { text: 'Test Inc', value: 'gid://gitlab/CustomerRelations::Organization/1' },
          ],
        },
        { name: 'description', label: 'Description' },
      ]);
    });

    it('renders correct title prop', () => {
      expect(findContactForm().props('title')).toBe(title);
    });

    it('renders correct successMessage prop', () => {
      expect(findContactForm().props('successMessage')).toBe(successMessage);
    });
  });
});
