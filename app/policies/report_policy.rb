class ReportPolicy
  def initialize(user, organization)
    @membership = user.memberships.find_by(organization: organization)
  end

  def show?
    organizer?
  end

  private

  def organizer?
    @membership&.owner? || @membership&.officer? || @membership&.coordinator?
  end
end
