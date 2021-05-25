defmodule GroupherServer.Repo.Migrations.AddContributesDigestFieldToCommunity do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:contributes_digest, {:array, :integer}, default: [])
    end
  end
end
