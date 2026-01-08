require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  def setup
    @publisher = Publisher.create!(name: 'Test Publisher')
  end

  test "should have valid product types" do
    product = Product.new(
      name: 'Test Product',
      product_type: 'Agent',
      price_model: 'Free',
      publisher: @publisher
    )
    assert product.valid?
  end

  test "should reject invalid product type" do
    product = Product.new(
      name: 'Test Product',
      product_type: 'InvalidType',
      price_model: 'Free',
      publisher: @publisher
    )
    assert_not product.valid?
  end

  test "should display price correctly for free products" do
    product = Product.new(price_model: 'Free')
    assert_equal 'Free', product.price_display
  end

  test "should display price correctly for paid products" do
    product = Product.new(price_model: 'Paid', price: 99.00)
    assert_equal '$99.0/month', product.price_display
  end

  test "should display price correctly for contact pricing" do
    product = Product.new(price_model: 'Contact')
    assert_equal 'Contact for pricing', product.price_display
  end
end
