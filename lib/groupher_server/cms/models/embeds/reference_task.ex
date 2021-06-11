defmodule GroupherServer.CMS.Model.Embeds.ReferenceTask do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  @optional_fields ~w(bi_link_tasks mention_user_tasks)a

  # thread, article_id, block_id, author_id, cite_thread, cite_article_id, cite_block_id, cite_author_id

  @doc "for test usage"
  def default_meta() do
    %{
      # bi_link_tasks: [],
      # mention_user_tasks: []
    }
  end

  embedded_schema do
    field(:article_id, :id)
    field(:block_id, :string)

    field(:reference_article_id, :id)
    # 可选
    field(:reference_block_id, :string)

    field(:is_finished, :boolean, default: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
