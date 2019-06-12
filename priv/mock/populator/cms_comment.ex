defmodule GroupherServer.Mock.CMS.Comment do
  # alias GroupherServer.Repo
  # alias GroupherServer.CMS

  # CMS.comment_post(post_id, body)

  # def random_attrs do
  # %{
  # title: Faker.Name.first_name() <> " " <> Faker.Name.last_name(),
  # body: Faker.Lorem.paragraph(%Range{first: 1, last: 2})
  # }
  # end

  def random(count \\ 1) do
    for _u <- 1..count do
      # CMS.create_comment(:post, :comment, 21, 39, "fake comment")
    end
  end

  # defp insert_multi do
  # Post.changeset(%Post{}, random_attrs())
  # |> Repo.insert!()
  # end
end
