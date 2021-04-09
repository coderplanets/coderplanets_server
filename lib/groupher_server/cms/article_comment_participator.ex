defmodule GroupherServer.CMS.ArticleCommentParticipator do
  @moduledoc false

  use Ecto.Schema

  alias GroupherServer.Accounts.User

  # alias CMS.{
  #   Post,
  #   Job,
  #   ArticleCommentUpvote
  # }

  # alias Helper.HTML

  # @required_fields ~w(user_id)a
  # @optional_fields ~w(post_id job_id)a

  embedded_schema do
    # field(:reply_time, :string)

    belongs_to(:user, User)
  end
end
