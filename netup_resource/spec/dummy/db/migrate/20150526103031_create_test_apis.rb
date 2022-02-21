class CreateTestApis < ActiveRecord::Migration
  def change
    create_table :test_apis do |t|

      t.timestamps
    end
  end
end
