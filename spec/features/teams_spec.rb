require 'rails_helper'

feature 'Teams support' do
  let!(:registry) { create(:registry) }
  let!(:user) { create(:admin) }
  let!(:team) { create(:team, owners: [user]) }

  before do
    login_as user, scope: :user
  end

  describe 'teams#index' do
    scenario 'A user cannot create an empty team', js: true do
      teams_count = Team.count

      visit teams_path
      find('#add_team_btn').click
      wait_for_effect_on('#add_team_form')

      click_button 'Add'
      wait_for_ajax
      wait_for_effect_on('#add_team_form')
      expect(Team.count).to eql teams_count
      expect(current_path).to eql teams_path
    end

    scenario 'A team cannot be created if the name has already been picked', js: true do
      teams_count = Team.count

      visit teams_path
      find('#add_team_btn').click
      fill_in 'Name', with: Team.first.name
      wait_for_effect_on('#add_team_form')

      click_button 'Add'
      wait_for_ajax
      wait_for_effect_on('#alert')
      expect(Team.count).to eql teams_count
      expect(current_path).to eql teams_path
      expect(page).to have_content('Name has already been taken')
      expect(page).to have_css('#alert .alert.alert-dismissible.alert-info')
    end

    scenario 'A team can be created from the index page', js: true do
      teams_count = Team.count

      visit teams_path
      find('#add_team_btn').click
      fill_in 'Name', with: 'valid-team'
      wait_for_effect_on('#add_team_form')

      click_button 'Add'
      wait_for_ajax
      wait_for_effect_on('#add_team_form')
      expect(Team.count).to eql teams_count + 1
      expect(current_path).to eql teams_path
      expect(page).to have_content('valid-team')
    end

    scenario 'The "Create new team" link has a toggle effect', js: true do
      visit teams_path
      expect(page).to have_css('#add_team_btn i.fa-plus-circle')
      expect(page).to_not have_css('#add_team_btn i.fa-minus-circle')

      find('#add_team_btn').click
      wait_for_effect_on('#add_team_form')

      expect(page).to_not have_css('#add_team_btn i.fa-plus-circle')
      expect(page).to have_css('#add_team_btn i.fa-minus-circle')

      find('#add_team_btn').click
      wait_for_effect_on('#add_team_form')

      expect(page).to have_css('#add_team_btn i.fa-plus-circle')
      expect(page).to_not have_css('#add_team_btn i.fa-minus-circle')
    end

    scenario 'The name of each team is a link' do
      visit teams_path
      expect(page).to have_content(team.name)
      find('#teams a').click
      expect(current_path).to eq team_path(team)
    end
  end

  describe 'teams#show' do
    scenario 'A namespace can be created from the team page', js: true do
      visit team_path(team)

      # The form appears after clicking the "Add namespace" link.
      expect(find('#add_namespace_form', visible: false)).to_not be_visible
      find('#add_namespace_btn').click
      wait_for_effect_on('#add_namespace_form')
      expect(find('#add_namespace_form')).to be_visible
      expect(focused_element_id).to eq 'namespace_namespace'

      # Fill the form and wait for the AJAX response.
      fill_in 'Namespace', with: 'new-namespace'
      click_button 'Add'
      wait_for_ajax

      # See the response.
      namespace = Namespace.find_by(name: 'new-namespace')
      expect(page).to have_css("#namespace_#{namespace.id}")
      wait_for_effect_on('#add_namespace_form')
      expect(find('#add_namespace_form', visible: false)).to_not be_visible
    end
  end
end
