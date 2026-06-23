class OrganizationPolicy
  def initialize(user, organization)
    @membership = user.memberships.find_by(organization: organization)
  end

  def show?
    @membership.present?
  end

  def manage?
    @membership&.owner? || @membership&.officer?
  end

  def transfer_ownership?
    @membership&.owner?
  end

  def archive?
    @membership&.owner?
  end

  def restore?
    archive?
  end
end
