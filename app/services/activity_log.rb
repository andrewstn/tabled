class ActivityLog
  SENSITIVE_KEY_PATTERN = /password|token|secret|credential|code/i

  def self.record!(organization:, action:, summary:, actor: nil, subject: nil, metadata: {}, occurred_at: nil)
    raise ArgumentError, "organization is required" unless organization

    organization.activity_log_entries.create!(
      actor: actor,
      action: action,
      subject: subject,
      summary: summary,
      occurred_at: occurred_at,
      metadata: safe_metadata(metadata)
    )
  end

  def self.record(**attributes)
    record!(**attributes)
  rescue StandardError => error
    Rails.logger.warn("ActivityLog failed: #{error.class}: #{error.message}")
    nil
  end

  def self.safe_metadata(metadata)
    metadata.to_h.each_with_object({}) do |(key, value), safe|
      next if key.to_s.match?(SENSITIVE_KEY_PATTERN)

      safe[key.to_s] = safe_value(value)
    end
  end

  def self.safe_value(value)
    case value
    when Hash
      safe_metadata(value)
    when Array
      value.map { |item| safe_value(item) }
    else
      value
    end
  end

  private_class_method :safe_metadata, :safe_value
end
