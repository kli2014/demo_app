class ProductRequirement < ActiveRecord::Base
  REQUIREMENT_TYPES = %w[microsoft partner complementary].freeze

  belongs_to :product
  belongs_to :required_product, class_name: 'Product'

  validates :requirement_type, inclusion: { in: REQUIREMENT_TYPES }
end
