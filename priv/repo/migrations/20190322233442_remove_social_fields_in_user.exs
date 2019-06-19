defmodule GroupherServer.Repo.Migrations.RemoveSocialFieldsInUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:github)
      remove(:twitter)
      remove(:facebook)
      remove(:zhihu)
      remove(:dribble)
      remove(:huaban)
      remove(:douban)
      remove(:pinterest)
      remove(:instagram)
      remove(:weichat)
      remove(:weibo)
    end
  end
end
