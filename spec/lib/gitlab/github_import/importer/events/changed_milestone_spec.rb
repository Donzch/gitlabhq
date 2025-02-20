# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::ChangedMilestone do
  subject(:importer) { described_class.new(project, user.id) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:issue) { create(:issue, project: project) }
  let!(:milestone) { create(:milestone, project: project) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => 4, 'login' => 'alice' },
      'event' => event_type,
      'commit_id' => nil,
      'milestone_title' => milestone.title,
      'issue_db_id' => issue.id,
      'created_at' => '2022-04-26 18:30:53 UTC'
    )
  end

  let(:event_attrs) do
    {
      user_id: user.id,
      issue_id: issue.id,
      milestone_id: milestone.id,
      state: 'opened',
      created_at: issue_event.created_at
    }.stringify_keys
  end

  shared_examples 'new event' do
    it 'creates a new milestone event' do
      expect { importer.execute(issue_event) }.to change { issue.resource_milestone_events.count }
        .from(0).to(1)
      expect(issue.resource_milestone_events.last)
        .to have_attributes(expected_event_attrs)
    end
  end

  describe '#execute' do
    before do
      allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(milestone.id)
    end

    context 'when importing a milestoned event' do
      let(:event_type) { 'milestoned' }
      let(:expected_event_attrs) { event_attrs.merge(action: 'add') }

      it_behaves_like 'new event'
    end

    context 'when importing demilestoned event' do
      let(:event_type) { 'demilestoned' }
      let(:expected_event_attrs) { event_attrs.merge(action: 'remove') }

      it_behaves_like 'new event'
    end
  end
end
