# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User merges a merge request", :js do
  let(:user) { project.first_owner }

  before do
    sign_in(user)
  end

  shared_examples "fast forward merge a merge request" do
    it "merges a merge request", :sidekiq_inline do
      expect(page).to have_content("Fast-forward merge without a merge commit").and have_button("Merge")

      page.within(".mr-state-widget") do
        click_button("Merge")
      end

      expect(page).to have_selector('.gl-badge', text: 'Merged')
    end
  end

  context "ff-only merge" do
    let(:project) { create(:project, :public, :repository, merge_requests_ff_only_enabled: true) }

    before do
      stub_feature_flags(restructured_mr_widget: false)
      visit(merge_request_path(merge_request))
    end

    context "when branch is rebased" do
      let!(:merge_request) { create(:merge_request, :rebased, source_project: project) }

      it_behaves_like "fast forward merge a merge request"
    end

    context "when branch is merged" do
      let!(:merge_request) { create(:merge_request, :merged_target, source_project: project) }

      it_behaves_like "fast forward merge a merge request"
    end
  end

  context 'sidebar merge requests counter' do
    let(:project) { create(:project, :public, :repository) }
    let!(:merge_request) { create(:merge_request, source_project: project) }

    it 'decrements the open MR count', :sidekiq_inline do
      create(:merge_request, source_project: project, source_branch: 'branch-1')

      visit(merge_request_path(merge_request))

      expect(page).to have_css('.js-merge-counter', text: '2')

      page.within(".mr-state-widget") do
        click_button("Merge")
      end

      expect(page).to have_css('.js-merge-counter', text: '1')
    end
  end
end
