# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User creates a merge request", :js do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:title) { "Some feature" }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it "creates a merge request" do
    visit(project_new_merge_request_path(project))

    find(".js-source-branch").click
    click_link("fix")

    find(".js-target-branch").click
    click_link("feature")

    click_button("Compare branches")

    page.within('.merge-request-form') do
      expect(page.find('#merge_request_description')['placeholder']).to eq 'Describe the goal of the changes and what reviewers should be aware of.'
    end

    fill_in("Title", with: title)
    click_button("Create merge request")

    page.within(".merge-request") do
      expect(page).to have_content(title)
    end
  end

  context "XSS branch name exists" do
    before do
      project.repository.create_branch("<img/src='x'/onerror=alert('oops')>", "master")
    end

    it "doesn't execute the dodgy branch name" do
      visit(project_new_merge_request_path(project))

      find(".js-source-branch").click
      click_link("<img/src='x'/onerror=alert('oops')>")

      find(".js-target-branch").click
      click_link("feature")

      click_button("Compare branches")

      expect { page.driver.browser.switch_to.alert }.to raise_error(Selenium::WebDriver::Error::NoSuchAlertError)
    end
  end

  context "to a forked project" do
    let(:forked_project) { fork_project(project, user, namespace: user.namespace, repository: true) }

    it "creates a merge request", :sidekiq_might_not_need_inline do
      visit(project_new_merge_request_path(forked_project))

      expect(page).to have_content("Source branch").and have_content("Target branch")
      expect(find("#merge_request_target_project_id", visible: false).value).to eq(project.id.to_s)

      click_button("Compare branches and continue")

      expect(page).to have_content("You must select source and target branch")

      first(".js-source-project").click
      first(".dropdown-source-project a", text: forked_project.full_path)

      first(".js-target-project").click
      first(".dropdown-target-project a", text: project.full_path)

      first(".js-source-branch").click

      wait_for_requests

      source_branch = "fix"

      first(".js-source-branch-dropdown .dropdown-content a", text: source_branch).click

      click_button("Compare branches and continue")

      expect(page).to have_text _('New merge request')

      page.within("form#new_merge_request") do
        fill_in("Title", with: title)
      end

      expect(find(".js-assignee-search")["data-project-id"]).to eq(project.id.to_s)
      find('.js-assignee-search').click

      page.within(".dropdown-menu-user") do
        expect(page).to have_content("Unassigned")
                   .and have_content(user.name)
                   .and have_content(project.users.first.name)
      end
      find('.js-assignee-search').click

      click_button("Create merge request")

      expect(page).to have_content(title).and have_content("requested to merge #{forked_project.full_path}:#{source_branch} into master")
    end
  end
end
