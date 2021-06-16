defmodule GroupherServer.Delivery.Delegate.Mentions do
  @moduledoc """
  The Delivery context.
  """
  import Helper.Utils, only: [stringfy: 1, integerfy: 1]

  alias GroupherServer.{Accounts, Delivery, Repo}

  alias Accounts.Model.User
  alias Delivery.Model.OldMention
  alias Delivery.Delegate.Utils

  # TODO: move mention logic to create contents
  # TODO: 同一篇文章不能 mention 同一个 user 多次？
  def mention_others(%User{id: _from_user_id}, [], _info), do: {:error, %{done: false}}
  def mention_others(%User{id: _from_user_id}, nil, _info), do: {:error, %{done: false}}
  def mention_others(%User{id: _from_user_id}, [nil], _info), do: {:error, %{done: false}}

  def mention_others(%User{id: from_user_id}, to_uses, info) do
    other_users = Enum.uniq(to_uses)

    records =
      Enum.reduce(other_users, [], fn to_user, acc ->
        attrs = %{
          from_user_id: from_user_id,
          to_user_id: integerfy(to_user.id),
          source_id: stringfy(info.source_id),
          # source_title has 256 limit under table
          # chinese takes 2 chars
          source_title: String.slice(info.source_title, 0, 50),
          source_type: info.source_type,
          # source_preview has 256 limit under table
          # chinese takes 2 chars
          source_preview: String.slice(info.source_preview, 0, 50),
          parent_id: stringfy(Map.get(info, :parent_id)),
          parent_type: stringfy(Map.get(info, :parent_type)),
          community: Map.get(info, :community),
          # timestamp are not auto-gen, see:
          # https://stackoverflow.com/questions/37537094/insert-all-does-not-create-auto-generated-inserted-at-with-ecto-2-0/46844417
          # Ecto.DateTime.utc(),
          inserted_at: DateTime.truncate(Timex.now(), :second),
          # Ecto.DateTime.utc()
          updated_at: DateTime.truncate(Timex.now(), :second)
        }

        attrs =
          if Map.has_key?(info, :floor),
            do: Map.merge(attrs, %{floor: integerfy(info.floor)}),
            else: attrs

        acc ++ [attrs]
      end)

    Repo.insert_all(OldMention, records)

    {:ok, %{done: true}}
    # |> done(:status)
  end

  """
  title:
  thread:
  id
  block_linker
  comment_id
  """

  # def mention_from_article()
  # deff mention_from_comment()

  def mention_from_content(community, :post, content, args, %User{} = from_user) do
    to_user_ids = Map.get(args, :mention_users)
    topic = Map.get(args, :topic, "posts")

    info = %{
      source_title: String.slice(content.title, 0, 50),
      source_type: topic,
      source_id: content.id,
      source_preview: String.slice(content.digest, 0, 50),
      community: community
    }

    mention_others(from_user, to_user_ids, info)
  end

  def mention_from_content(community, :job, content, args, %User{} = from_user) do
    to_user_ids = Map.get(args, :mention_users)

    info = %{
      source_title: String.slice(content.title, 0, 50),
      source_type: "job",
      source_id: content.id,
      source_preview: String.slice(content.digest, 0, 50),
      community: community
    }

    mention_others(from_user, to_user_ids, info)
  end

  def mention_from_content(_community, _thread, _, _, _user), do: {:ok, :pass}

  def mention_from_comment(community, thread, content, comment, args, %User{} = from_user) do
    to_user_ids = Map.get(args, :mention_users)

    info = %{
      source_title: String.slice(content.title, 0, 50),
      source_type: "comment",
      source_id: comment.id,
      source_preview: String.slice(comment.body, 0, 50),
      floor: comment.floor,
      parent_id: content.id,
      parent_type: thread,
      community: community
    }

    mention_others(from_user, to_user_ids, info)
  end

  defp get_reply_content_id(:post, comment), do: comment.post_id
  defp get_reply_content_id(:job, comment), do: comment.job_id
  defp get_reply_content_id(:repo, comment), do: comment.repo_id

  def mention_from_comment_reply(community, thread, comment, args, %User{} = from_user) do
    # IO.inspect comment, label: "reply this comment"
    content_id = get_reply_content_id(thread, comment)
    to_user_ids = Map.get(args, :mention_users)

    info = %{
      source_title: String.slice(comment.body, 0, 50),
      source_type: "comment_reply",
      source_id: content_id,
      source_preview: String.slice(args.body, 0, 50),
      floor: args.floor,
      parent_id: content_id,
      parent_type: thread,
      community: community
    }

    mention_others(from_user, to_user_ids, info)
    mention_others(from_user, [%{id: comment.author_id}], info)
  end

  @doc """
  fetch mentions from Delivery stop
  """
  def fetch_mentions(%User{} = user, %{page: _, size: _, read: _} = filter) do
    Utils.fetch_messages(user, OldMention, filter)
  end
end
