class OwnershipTransfer
  attr_reader :membership

  def initialize(organization:, target_membership_id:)
    @organization = organization
    @target_membership_id = target_membership_id
  end

  def transfer
    @membership = @organization.memberships.find_by(id: @target_membership_id)
    return false unless @membership

    @membership.update(role: :owner)
  end
end
