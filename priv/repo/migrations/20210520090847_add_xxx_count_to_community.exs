defmodule GroupherServer.Repo.Migrations.AddXxxCountToCommunity do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:articles_count, :integer, default: 0)
      add(:editors_count, :integer, default: 0)
      add(:subscribers_count, :integer, default: 0)
    end
  end
end
