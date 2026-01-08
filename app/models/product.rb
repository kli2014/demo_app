class Product < ActiveRecord::Base
  PRODUCT_TYPES = %w[Agent Connector SaaS Service].freeze
  PRICE_MODELS = %w[Free Paid Contact].freeze

  belongs_to :publisher
  has_many :product_requirements
  has_many :required_products, through: :product_requirements
  has_many :subscriptions

  validates :name, presence: true
  validates :product_type, inclusion: { in: PRODUCT_TYPES }
  validates :price_model, inclusion: { in: PRICE_MODELS }

  serialize :screenshots, Array
  serialize :permissions, Array

  scope :by_type, ->(type) { where(product_type: type) if type.present? }
  scope :microsoft_products, -> { where(is_microsoft_product: true) }
  scope :partner_products, -> { where(is_microsoft_product: false) }

  def microsoft_requirements
    product_requirements.joins(:required_product).where(requirement_type: 'microsoft', products: { is_microsoft_product: true })
  end

  def partner_requirements
    product_requirements.joins(:required_product).where(requirement_type: 'partner', products: { is_microsoft_product: false })
  end

  def complementary_products
    product_requirements.joins(:required_product).where(requirement_type: 'complementary')
  end

  def required_microsoft_products
    Product.joins("INNER JOIN product_requirements ON products.id = product_requirements.required_product_id")
           .where(product_requirements: { product_id: id, requirement_type: 'microsoft' })
  end

  def required_partner_products
    Product.joins("INNER JOIN product_requirements ON products.id = product_requirements.required_product_id")
           .where(product_requirements: { product_id: id, requirement_type: 'partner' })
  end

  def complementary_product_list
    Product.joins("INNER JOIN product_requirements ON products.id = product_requirements.required_product_id")
           .where(product_requirements: { product_id: id, requirement_type: 'complementary' })
  end

  def price_display
    case price_model
    when 'Free'
      'Free'
    when 'Paid'
      price.present? ? "$#{price}/month" : 'Paid'
    when 'Contact'
      'Contact for pricing'
    end
  end
end
