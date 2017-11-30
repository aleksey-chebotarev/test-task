class CreateForumUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :forum_users do |t|
      t.string :username
      t.string :profile_url
      t.string :avatar_image
      t.date :last_scraped_date

      t.timestamps
    end

    add_index :forum_users, :username
    add_index :forum_users, :last_scraped_date
  end
end
