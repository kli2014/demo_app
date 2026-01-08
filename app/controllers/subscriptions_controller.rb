class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [:show, :destroy, :retry_deployment]

  # GET /solutions - My Solutions dashboard grouped by publisher
  def index
    if current_user
      @subscriptions_by_publisher = Subscription.grouped_by_publisher(current_user)
    else
      @subscriptions_by_publisher = {}
    end
  end

  # GET /subscriptions/:id
  def show
    @related_subscriptions = @subscription.all_related_subscriptions
  end

  # GET /store/:product_id/subscribe - Subscribe flow
  def new
    @product = Product.includes(:publisher, product_requirements: :required_product).find(params[:product_id])
    @microsoft_products = @product.required_microsoft_products.includes(:publisher)
    @partner_products = @product.required_partner_products.includes(:publisher)
    @complementary_products = @product.complementary_product_list.includes(:publisher)
    
    # Check which Microsoft products the user already has (simulated)
    @available_microsoft_products = simulate_microsoft_product_availability
  end

  # POST /subscriptions - Create subscription and deploy
  def create
    @product = Product.find(params[:product_id])
    
    # Create main subscription
    @subscription = Subscription.new(
      user: current_user,
      product: @product,
      status: 'pending',
      config_data: subscription_params[:config_data] || {}
    )

    if @subscription.save
      # Create child subscriptions for selected products
      create_child_subscriptions(params[:selected_products] || [])
      
      # Start deployment simulation
      deploy_subscriptions
      
      redirect_to subscription_path(@subscription), notice: 'Deployment started successfully.'
    else
      @microsoft_products = @product.required_microsoft_products.includes(:publisher)
      @partner_products = @product.required_partner_products.includes(:publisher)
      @complementary_products = @product.complementary_product_list.includes(:publisher)
      @available_microsoft_products = simulate_microsoft_product_availability
      render :new
    end
  end

  # POST /subscriptions/:id/retry
  def retry_deployment
    if @subscription.requires_action?
      @subscription.update(status: 'deploying')
      # Simulate retry deployment
      redirect_to @subscription, notice: 'Retrying deployment...'
    else
      redirect_to @subscription, alert: 'Cannot retry this subscription.'
    end
  end

  # DELETE /subscriptions/:id
  def destroy
    @subscription.child_subscriptions.destroy_all
    @subscription.destroy
    redirect_to solutions_path, notice: 'Subscription removed successfully.'
  end

  private

  def set_subscription
    @subscription = Subscription.includes(:product, :child_subscriptions).find(params[:id])
  end

  def subscription_params
    params.require(:subscription).permit(:config_data, config_data: [:contact_name, :contact_email, :contact_phone])
  rescue ActionController::ParameterMissing
    {}
  end

  def current_user
    # For demo purposes, return the first user or create one
    @current_user ||= User.first || User.create!(name: 'Demo User', email: 'demo@example.com')
  end

  def simulate_microsoft_product_availability
    # Simulate that user has Microsoft Sentinel but not Security Copilot
    Product.microsoft_products.each_with_object({}) do |product, hash|
      hash[product.id] = product.name.include?('Sentinel')
    end
  end

  def create_child_subscriptions(selected_product_ids)
    selected_product_ids.each do |product_id|
      product = Product.find_by(id: product_id)
      next unless product

      @subscription.child_subscriptions.create!(
        user: current_user,
        product: product,
        status: 'pending'
      )
    end
  end

  def deploy_subscriptions
    # Deployment order: main product first, then required, then complementary
    all_subs = [@subscription] + @subscription.child_subscriptions.to_a
    
    all_subs.each_with_index do |sub, index|
      # Simulate deployment - some succeed, some may fail
      # For demo: Azure Security Connector fails due to permissions
      if sub.product.name.include?('Connector')
        sub.mark_action_required!("You don't have permissions to deploy this product. You need to be a Sentinel Contributor.")
      else
        sub.mark_deployed!
      end
    end
  end
end
