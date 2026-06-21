require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "labels the current academic term without a semester model" do
    assert_equal "Spring 2026", current_semester_label(Date.new(2026, 2, 1))
    assert_equal "Summer 2026", current_semester_label(Date.new(2026, 6, 1))
    assert_equal "Fall 2026", current_semester_label(Date.new(2026, 10, 1))
  end
end
