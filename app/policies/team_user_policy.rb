class TeamUserPolicy
  attr_reader :user, :team_user

  def initialize(user, team_user)
    fail Pundit::NotAuthorizedError, 'must be logged in' unless user
    @user = user
    @team_user = team_user
  end

  def owner?
    user.admin? || @team_user.team.owners.exists?(user.id)
  end

  alias_method :destroy?, :owner?
  alias_method :update?, :owner?
  alias_method :create?, :owner?
end
