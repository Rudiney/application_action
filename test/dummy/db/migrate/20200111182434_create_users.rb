class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :name
      t.bigint :posts_count

      t.timestamps
    end
  end
end
