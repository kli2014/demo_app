class Subscription < ActiveRecord::Base
  STATUSES = %w[pending deploying deployed failed skipped action_required].freeze

  belongs_to :user
  belongs_to :product
  belongs_to :parent_subscription, class_name: 'Subscription'
  has_many :child_subscriptions, class_name: 'Subscription', foreign_key: :parent_subscription_id

  validates :status, inclusion: { in: STATUSES }

  serialize :config_data, Hash

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :deployed, -> { where(status: 'deployed') }
  scope :failed, -> { where(status: 'failed') }
  scope :action_required, -> { where(status: 'action_required') }
  scope :main_subscriptions, -> { where(parent_subscription_id: nil) }

  def self.grouped_by_publisher(user)
    includes(product: :publisher)
      .where(user_id: user.id, parent_subscription_id: nil)
      .group_by { |s| s.product.publisher }
  end

  def mark_deployed!
    update(status: 'deployed', deployed_at: Time.current, error_message: nil)
  end

  def mark_failed!(message)
    update(status: 'failed', error_message: message)
  end

  def mark_action_required!(message)
    update(status: 'action_required', error_message: message)
  end

  def requires_action?
    status == 'action_required' || status == 'failed'
  end

  def all_related_subscriptions
    [self] + child_subscriptions.to_a
  end

  def deployment_complete?
    all_related_subscriptions.all? { |s| s.status == 'deployed' || s.status == 'skipped' }
  end

  def has_failures?
    all_related_subscriptions.any? { |s| s.status == 'failed' || s.status == 'action_required' }
  end
end
