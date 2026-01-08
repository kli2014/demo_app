class CreateProductRequirements < ActiveRecord::Migration
  def change
    create_table :product_requirements do |t|
      t.references :product, index: true
      t.references :required_product, index: true
      t.string :requirement_type  # microsoft, partner, complementary
      t.boolean :is_required, default: true

      t.timestamps
    end

    add_foreign_key :product_requirements, :products, column: :required_product_id
  end
end
