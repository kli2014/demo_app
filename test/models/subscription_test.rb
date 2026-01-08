require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: 'Test User', email: 'test@example.com')
    @publisher = Publisher.create!(name: 'Test Publisher')
    @product = Product.create!(
      name: 'Test Product',
      product_type: 'Agent',
      price_model: 'Free',
      publisher: @publisher
    )
  end

  test "should create valid subscription" do
    subscription = Subscription.new(
      user: @user,
      product: @product,
      status: 'pending'
    )
    assert subscription.valid?
  end

  test "should mark as deployed" do
    subscription = Subscription.create!(
      user: @user,
      product: @product,
      status: 'pending'
    )
    subscription.mark_deployed!
    assert_equal 'deployed', subscription.status
    assert_not_nil subscription.deployed_at
  end

  test "should mark as failed with message" do
    subscription = Subscription.create!(
      user: @user,
      product: @product,
      status: 'pending'
    )
    subscription.mark_failed!('Permission denied')
    assert_equal 'failed', subscription.status
    assert_equal 'Permission denied', subscription.error_message
  end

  test "should group by publisher" do
    subscription = Subscription.create!(
      user: @user,
      product: @product,
      status: 'deployed'
    )
    
    grouped = Subscription.grouped_by_publisher(@user)
    assert grouped.key?(@publisher)
    assert_equal 1, grouped[@publisher].length
  end

  test "should track parent-child relationships" do
    parent = Subscription.create!(
      user: @user,
      product: @product,
      status: 'deployed'
    )
    
    child_product = Product.create!(
      name: 'Child Product',
      product_type: 'Connector',
      price_model: 'Free',
      publisher: @publisher
    )
    
    child = Subscription.create!(
      user: @user,
      product: child_product,
      status: 'deployed',
      parent_subscription: parent
    )
    
    assert_equal 2, parent.all_related_subscriptions.length
    assert parent.deployment_complete?
  end

  test "should detect failures" do
    parent = Subscription.create!(
      user: @user,
      product: @product,
      status: 'deployed'
    )
    
    child_product = Product.create!(
      name: 'Failed Product',
      product_type: 'Connector',
      price_model: 'Free',
      publisher: @publisher
    )
    
    child = Subscription.create!(
      user: @user,
      product: child_product,
      status: 'failed',
      error_message: 'Deployment failed',
      parent_subscription: parent
    )
    
    assert parent.has_failures?
    assert child.requires_action?
  end
end
