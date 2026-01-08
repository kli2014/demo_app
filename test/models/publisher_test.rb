require 'test_helper'

class PublisherTest < ActiveSupport::TestCase
  test "should have valid attributes" do
    publisher = Publisher.new(name: 'Test Publisher', description: 'A test publisher')
    assert publisher.valid?
  end

  test "should require name" do
    publisher = Publisher.new(description: 'A test publisher')
    assert_not publisher.valid?
  end
end
