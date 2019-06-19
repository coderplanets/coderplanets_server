defmodule GroupherServer.Repo.Migrations.AddRawToThread do
  use Ecto.Migration

  def change do
    alter table(:community_threads) do
      add(:raw, :string)
      add(:logo, :text)
    end
  end
end
