defmodule GroupherServer.CMS.Helper.Utils do
  @moduledoc """
  utils for CMS helper
  """
  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]

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

  def articles_upvote_unique_key_constraint(%Ecto.Changeset{} = changeset) do
    # |> unique_constraint(:post_id, name: :article_upvotes_user_id_post_id_index)
    Enum.reduce(@article_fields, changeset, fn thread_id, acc ->
      unique_constraint(acc, thread_id, name: :"article_upvotes_user_id_#{thread_id}_index")
    end)
  end
end
