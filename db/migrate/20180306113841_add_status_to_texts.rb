class AddStatusToTexts < ActiveRecord::Migration[5.1]
  def change
    add_column :texts, :status, :string

    Texts.all.each do |text|
      text.status = "done"
      text.save
    end
  end

end
