require "test_helper"

class ActivityLogTest < ActiveSupport::TestCase
  test "record creates a scoped activity entry" do
    entry = ActivityLog.record!(
      organization: organizations(:film_society),
      actor: users(:owner),
      action: "event.created",
      subject: events(:upcoming_film_night),
      summary: "Alex created First Friday Film Night.",
      metadata: { event_title: "First Friday Film Night" }
    )

    assert_equal organizations(:film_society), entry.organization
    assert_equal users(:owner), entry.actor
    assert_equal events(:upcoming_film_night), entry.subject
    assert_equal "event.created", entry.action
    assert_equal "First Friday Film Night", entry.metadata["event_title"]
  end

  test "record requires an organization" do
    error = assert_raises(ArgumentError) do
      ActivityLog.record!(
        organization: nil,
        action: "event.created",
        summary: "Alex created First Friday Film Night."
      )
    end

    assert_equal "organization is required", error.message
  end

  test "record permits system activity without an actor" do
    entry = ActivityLog.record!(
      organization: organizations(:film_society),
      action: "roster.imported",
      summary: "A roster import completed."
    )

    assert_nil entry.actor
  end

  test "record accepts an explicit occurred at timestamp" do
    timestamp = 2.days.ago

    entry = ActivityLog.record!(
      organization: organizations(:film_society),
      action: "report.exported",
      summary: "Alex exported a report.",
      occurred_at: timestamp
    )

    assert_in_delta timestamp, entry.occurred_at, 1.second
  end

  test "record removes sensitive metadata keys" do
    entry = ActivityLog.record!(
      organization: organizations(:film_society),
      actor: users(:owner),
      action: "check_in.opened",
      summary: "Alex opened check-in.",
      metadata: {
        check_in_code: "123456",
        invitation_token: "secret",
        safe_count: 4,
        nested: { password: "hidden", status: "opened" }
      }
    )

    assert_not entry.metadata.key?("check_in_code")
    assert_not entry.metadata.key?("invitation_token")
    assert_equal 4, entry.metadata["safe_count"]
    assert_equal({ "status" => "opened" }, entry.metadata["nested"])
  end

  test "record returns nil instead of raising when logging fails" do
    result = ActivityLog.record(
      organization: organizations(:film_society),
      action: "",
      summary: ""
    )

    assert_nil result
  end
end
