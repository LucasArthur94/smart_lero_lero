class CreateTexts < ActiveRecord::Migration[5.1]
  def change
    create_table :texts do |t|
      t.string :words
      t.integer :paragraphs
      t.string :language_iso
      t.integer :char_quantity
      t.text :generated_text

      t.timestamps
    end
  end
end
