class RsvpUpdater
  attr_reader :rsvp

  def initialize(event:, membership:, attributes:, override_limits: false)
    @event = event
    @membership = membership
    @attributes = attributes
    @override_limits = override_limits
  end

  def save
    @event.with_lock do
      @rsvp = @event.rsvps.find_or_initialize_by(membership: @membership)
      @rsvp.assign_attributes(@attributes)
      enforce_limits unless @override_limits
      @rsvp.save if @rsvp.errors.empty?
    end
  end

  private

  def enforce_limits
    if @event.rsvp_deadline_passed?
      @rsvp.errors.add(:base, "RSVPs are closed for this gathering")
    end

    return unless @rsvp.attending?

    attending_rsvps = @event.rsvps.attending.where.not(id: @rsvp.id)
    if @event.capacity.present? && attending_rsvps.count >= @event.capacity
      @rsvp.errors.add(:base, "This gathering is full")
    end
  end
end
