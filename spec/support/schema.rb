ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, :force => true do |t|
    t.string :key
    t.string :name
    t.integer :age
    t.datetime :dob
    t.timestamps
  end

  create_table :wives, :force => true do |t|
    t.string :name
    t.integer :age
    t.integer :man_id
    t.timestamps
  end

  create_table :men, :force => true do |t|
    t.string :name
    t.references :wives
    t.timestamps
  end
end
