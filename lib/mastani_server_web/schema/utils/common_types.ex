defmodule MastaniServerWeb.Schema.Utils.CommonTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServerWeb.Repo

  object :status do
    field(:done, :boolean)
    field(:id, :id)
  end
end
