class AddProfilRelationnelToStates < ActiveRecord::Migration[7.1]
  def change
    add_column :states, :profil_relationnel, :string
  end
end
