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

  def view_activity?
    @membership&.owner? || @membership&.officer? || @membership&.coordinator?
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

  def destroy?
    archive? && @membership.organization.archived?
  end
end
