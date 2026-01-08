class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.text :overview
      t.string :product_type  # Agent, Connector, SaaS, Service
      t.string :price_model   # Free, Paid, Contact
      t.decimal :price, precision: 10, scale: 2
      t.references :publisher, index: true
      t.string :version
      t.string :icon_url
      t.text :screenshots     # serialized array of URLs
      t.text :permissions     # serialized array of required permissions
      t.boolean :is_microsoft_product, default: false
      t.string :external_url  # for Microsoft products, link to deployment
      t.string :cta_text      # Call-to-action text after deployment

      t.timestamps
    end
  end
end
