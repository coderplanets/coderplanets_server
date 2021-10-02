defmodule GroupherServer.Repo.Migrations.RemoveCityInfoInWorks do
  use Ecto.Migration

  def change do
    alter table(:cms_works) do
      remove(:city_info)
    end
  end
end
