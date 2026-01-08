class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.references :user, index: true
      t.references :product, index: true
      t.string :status        # pending, deploying, deployed, failed, skipped
      t.text :error_message
      t.datetime :deployed_at
      t.references :parent_subscription  # links to main product subscription
      t.text :config_data     # serialized configuration data

      t.timestamps
    end

    add_foreign_key :subscriptions, :subscriptions, column: :parent_subscription_id
  end
end
