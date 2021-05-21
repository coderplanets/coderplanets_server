defmodule GroupherServer.CMS.Embeds.CommunityMeta.Macro do
  @moduledoc false

  import Helper.Utils, only: [get_config: 2]

  @article_threads get_config(:article, :article_threads)

  defmacro thread_count_fields() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        field(unquote(:"#{thread}s_count"), :integer, default: 0)
      end
    end)
  end
end

defmodule GroupherServer.CMS.Embeds.CommunityMeta do
  @moduledoc """
  general community meta
  """
  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2]
  import GroupherServer.CMS.Embeds.CommunityMeta.Macro

  @article_threads get_config(:article, :article_threads)

  @general_options %{
    subscribed_user_ids: [],
    contributes_digest: []
  }

  @optional_fields Map.keys(@general_options) ++ Enum.map(@article_threads, &:"#{&1}s_count")

  def default_meta() do
    threads_counts =
      @article_threads
      |> Enum.reduce([], &(&2 ++ ["#{&1}s_count": 0]))
      |> Enum.into(%{})

    @general_options |> Map.merge(threads_counts)
  end

  embedded_schema do
    thread_count_fields()

    # 关注相关
    field(:subscribed_user_ids, {:array, :integer}, default: [])
    field(:contributes_digest, {:array, :integer}, default: [])
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
