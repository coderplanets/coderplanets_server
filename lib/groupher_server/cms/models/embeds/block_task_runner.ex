defmodule GroupherServer.CMS.Model.Embeds.BlockTaskRunner do
  @moduledoc """
  general article meta info for article-like content, like post, job, works ...
  """
  use Ecto.Schema
  use Accessible
  import Ecto.Changeset

  alias GroupherServer.CMS.Model.Embeds

  @optional_fields ~w(bi_link_tasks)a
  # @optional_fields ~w(bi_link_tasks mention_user_tasks)a

  @doc "for test usage"
  def default_meta() do
    %{
      bi_link_tasks: []
      # mention_user_tasks: []
    }
  end

  embedded_schema do
    embeds_many(:reference_tasks, Embeds.ReferenceTask, on_replace: :delete)
    # embeds_many(:mention_user_tasks, Embeds.MentionUserTask, on_replace: :delete)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
