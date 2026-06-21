class InvitationPolicy
  def initialize(user, organization)
    @actor = user.memberships.find_by(organization: organization)
  end

  def manage?
    @actor&.owner? || @actor&.officer?
  end

  def invite_as?(role)
    permitted_roles.include?(role.to_s)
  end

  def revoke?(invitation)
    manage? && permitted_roles.include?(invitation.role)
  end

  def permitted_roles
    return Membership::ROLES if @actor&.owner?
    return %w[coordinator member] if @actor&.officer?

    []
  end
end
