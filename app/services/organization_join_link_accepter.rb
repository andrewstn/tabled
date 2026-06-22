class OrganizationJoinLinkAccepter
  attr_reader :membership

  def initialize(join_link:, user:)
    @join_link = join_link
    @user = user
    @already_joined = false
  end

  def accept
    success = false

    OrganizationJoinLink.transaction do
      @join_link.lock!

      unless @join_link.available?
        @join_link.errors.add(:base, unavailable_message)
        raise ActiveRecord::Rollback
      end

      @membership = @join_link.organization.memberships.find_by(user: @user)
      if @membership
        @already_joined = true
        raise ActiveRecord::Rollback
      end

      @membership = @join_link.organization.memberships.create!(user: @user, role: @join_link.role)
      @join_link.increment!(:uses_count)
      success = true
    end

    success
  rescue ActiveRecord::RecordNotUnique
    @already_joined = true
    false
  end

  def already_joined?
    @already_joined
  end

  private

  def unavailable_message
    return "This recruitment link is no longer active" unless @join_link.active?
    return "This recruitment link has expired" if @join_link.expired?
    return "This recruitment link has reached its limit" if @join_link.full?

    "This recruitment link is unavailable"
  end
end
