class MembershipRoleUpdater
  def initialize(membership:, role:)
    @membership = membership
    @role = role.to_s
  end

  def update
    success = false

    Membership.transaction do
      owners = @membership.organization.memberships.owner.lock.to_a

      if @membership.owner? && @role != "owner" && owners.one?
        @membership.errors.add(:role, "cannot change because every organization needs an owner")
        raise ActiveRecord::Rollback
      end

      success = @membership.update(role: @role)
      raise ActiveRecord::Rollback unless success
    end

    success
  end
end
