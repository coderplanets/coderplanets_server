
# Statistics
#   |___ UserHeatMap

mix phx.gen.context Statistics UserContributes user_contributes user_id:references:users date:date count:integer

%{
  "js": %{
    "post-article-delete": true,
    "post-article-edit": true,
    "post-tag-edit": true,
    "post-tag-create": true,
    "post-tag-delete": true,
  }
}
