defmodule GroupherServer.Repo.Migrations.AddPinStateToPost do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:pin_states, :map)
    end
  end
end
