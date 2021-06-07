defmodule GroupherServer.CMS.Helper.Utils do
  @moduledoc """
  utils for CMS helper
  """
  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]

  alias GroupherServer.CMS

  @article_threads get_config(:article, :threads)
  @article_fields @article_threads |> Enum.map(&:"#{&1}_id")

  @doc """
  foreign_key_constraint for artilces thread

  e.g
  foreign_key_constraint(struct, :post_id)
  """
  def articles_foreign_key_constraint(%Ecto.Changeset{} = changeset) do
    Enum.reduce(@article_fields, changeset, fn thread_id, acc ->
      foreign_key_constraint(acc, thread_id)
    end)
  end
end
