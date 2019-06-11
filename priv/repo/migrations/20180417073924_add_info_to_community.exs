defmodule GroupherServer.Repo.Migrations.AddInfoToCommunity do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:raw, :string)
      add(:label, :string)
      add(:logo, :text)
    end
  end
end
