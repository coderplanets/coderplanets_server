defmodule MastaniServer.Repo.Migrations.RemovePinFromPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      remove(:pin_states)
      remove(:pin)
    end
  end
end
