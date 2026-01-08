class StoreController < ApplicationController
  def index
    @products = Product.partner_products.includes(:publisher)
    @products = @products.by_type(params[:type]) if params[:type].present?
    @product_types = Product::PRODUCT_TYPES
  end

  def show
    @product = Product.includes(:publisher, product_requirements: :required_product).find(params[:id])
    @microsoft_products = @product.required_microsoft_products.includes(:publisher)
    @partner_products = @product.required_partner_products.includes(:publisher)
    @complementary_products = @product.complementary_product_list.includes(:publisher)
  end
end
