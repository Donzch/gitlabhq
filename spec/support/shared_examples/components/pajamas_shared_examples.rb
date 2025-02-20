# frozen_string_literal: true

RSpec.shared_examples 'it renders help text' do
  it 'renders help text' do
    expect(page).to have_css('[data-testid="pajamas-component-help-text"]', text: help_text)
  end
end

RSpec.shared_examples 'it does not render help text' do
  it 'does not render help text' do
    expect(page).not_to have_css('[data-testid="pajamas-component-help-text"]')
  end
end
