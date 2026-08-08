require "test_helper"
require "rake"

class DemoRefreshTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |task| task.name == "demo:refresh" }
    Rake::Task["demo:refresh"].reenable
  end

  test "refresh keeps the public demo workspace current" do
    load Rails.root.join("db/seeds/demo.rb")

    stale_event = Organization.find_by!(slug: "buckeye-film-society").events.find_by!(title: "First Friday Film Night")
    stale_event.update!(
      starts_at: 2.years.ago.change(hour: 19, min: 0),
      ends_at: 2.years.ago.change(hour: 21, min: 0),
      rsvp_deadline: 2.years.ago.change(hour: 18, min: 0)
    )

    Rake::Task["demo:refresh"].invoke

    refreshed_event = Organization.find_by!(slug: "buckeye-film-society").events.find_by!(title: "First Friday Film Night")
    assert_operator refreshed_event.starts_at, :>, Time.current
    assert_operator refreshed_event.rsvp_deadline, :>, Time.current
    assert User.find_by!(email_address: "demo-owner@example.test").demo_account?
  end
end
