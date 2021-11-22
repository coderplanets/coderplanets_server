defmodule GroupherServer.CMS.Model.Embeds.CommunityMeta.Macro do
  @moduledoc false

  import Helper.Utils, only: [get_config: 2, plural: 1]

  @article_threads get_config(:article, :threads)

  defmacro thread_count_fields() do
    @article_threads
    |> Enum.map(fn thread ->
      quote do
        field(unquote(:"#{plural(thread)}_count"), :integer, default: 0)
      end
    end)
  end
end

defmodule GroupherServer.CMS.Model.Embeds.CommunityMeta do
  @moduledoc """
  general community meta
  """
  use Ecto.Schema
  use Accessible

  import Ecto.Changeset
  import Helper.Utils, only: [get_config: 2, plural: 1]
  import GroupherServer.CMS.Model.Embeds.CommunityMeta.Macro

  @article_threads get_config(:article, :threads)

  @general_options %{
    editors_ids: [],
    subscribed_user_ids: [],
    contributes_digest: [],
    apply_msg: "",
    apply_category: ""
  }

  @optional_fields Map.keys(@general_options) ++
                     Enum.map(@article_threads, &:"#{plural(&1)}_count")

  def default_meta() do
    threads_counts =
      @article_threads
      |> Enum.reduce([], &(&2 ++ ["#{plural(&1)}_count": 0]))
      |> Enum.into(%{})

    @general_options |> Map.merge(threads_counts)
  end

  embedded_schema do
    thread_count_fields()

    field(:editors_ids, {:array, :integer}, default: [])
    # 关注相关
    field(:subscribed_user_ids, {:array, :integer}, default: [])
    field(:contributes_digest, {:array, :integer}, default: [])
    # 申请信息
    field(:apply_msg, :string, default: "")
    field(:apply_category, :string, default: "")
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @optional_fields)
  end
end
