class CreatePublishers < ActiveRecord::Migration
  def change
    create_table :publishers do |t|
      t.string :name
      t.text :description
      t.string :logo_url
      t.string :website_url

      t.timestamps
    end
  end
end
