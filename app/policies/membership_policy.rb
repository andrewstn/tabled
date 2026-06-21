class MembershipPolicy
  def initialize(user, organization, membership)
    @actor = user.memberships.find_by(organization: organization)
    @membership = membership
  end

  def update_role?(new_role)
    permitted_roles.include?(new_role.to_s)
  end

  def permitted_roles
    return Membership::ROLES if @actor&.owner?
    return %w[coordinator member] if @actor&.officer? && (@membership.coordinator? || @membership.member?)

    []
  end
end
