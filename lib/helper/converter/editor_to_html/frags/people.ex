defmodule Helper.Converter.EditorToHTML.Frags.People do
  @moduledoc """
  parse editor.js's block fragments, use for test too

  see https://editorjs.io/
  """
  import Helper.Utils, only: [get_config: 2]

  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Types, as: T

  @static_icon get_config(:cloud_assets, :static_icon)

  @class get_in(Class.article(), ["people"])
  @class_hide get_in(Class.article(), ["hide"])

  def get_previewer(:gallery, items) when length(items) > 1 do
    gallery_previewer_wrapper_class = @class["gallery_previewer_wrapper"]

    previewer_content =
      Enum.reduce(items, "", fn item, acc ->
        acc <> frag(:previewer_item, item, acc)
      end)

    ~s(<div class="#{gallery_previewer_wrapper_class}">
        #{previewer_content}
      </div>
    )
  end

  # if list item < 2 then return empty string, means no previewer
  def get_previewer(:gallery, _items), do: ""

  @doc """
  render every card, use display block/none to switch between them
  """
  @spec get_card(:gallery, [T.editor_people_item()]) :: T.html()
  def get_card(:gallery, items) do
    Enum.reduce(items, "", fn item, acc -> acc <> frag(:card, item, acc) end)
  end

  @spec frag(:card, T.editor_people_item(), String.t()) :: T.html()
  defp frag(
         :card,
         %{
           "id" => id,
           "avatar" => avatar,
           "title" => title,
           "bio" => bio,
           "desc" => desc,
           "socials" => socials
         },
         acc
       ) do
    # hide all by default except first
    gallery_card_wrapper_class =
      if byte_size(acc) == 0,
        do: @class["gallery_card_wrapper"],
        else: @class["gallery_card_wrapper"] <> " " <> @class_hide

    gallery_avatar_class = @class["gallery_avatar"]
    gallery_intro_class = @class["gallery_intro"]
    gallery_intro_title_class = @class["gallery_intro_title"]
    gallery_intro_bio_class = @class["gallery_intro_bio"]
    gallery_intro_desc_class = @class["gallery_intro_desc"]

    gallery_social_wrapper_class = @class["gallery_social_wrapper"]

    social_content = Enum.reduce(socials, "", fn item, acc -> acc <> frag(:social, item) end)

    ~s(<div class="#{gallery_card_wrapper_class}" data-index="#{id}">
         <div class="#{gallery_avatar_class}">
           <img src="#{avatar}" />
         </div>
         <div class="#{gallery_intro_class}">
          <div class="#{gallery_intro_title_class}">
            #{title}
          </div>
          <div class="#{gallery_intro_bio_class}">
            #{bio}
          </div>
          <div class="#{gallery_intro_desc_class}">
            #{desc}
          </div>
          <div class="#{gallery_social_wrapper_class}">
            #{social_content}
          </div>
         </div>
      </div>)
  end

  @spec frag(:previewer_item, T.editor_people_item(), T.string()) :: T.html()
  defp frag(:previewer_item, item, acc) do
    avatar = item["avatar"]
    gallery_previewer_item_class = @class["gallery_previewer_item"]

    active_class = if byte_size(acc) == 0, do: @class["gallery_previewer_active_item"], else: ""
    id = item["id"]

    ~s(<div class="#{gallery_previewer_item_class} #{active_class}" data-index="#{id}">
        <img src="#{avatar}" />
      </div>)
  end

  @spec frag(:social, T.editor_social_item()) :: T.html()
  defp frag(:social, %{"name" => name, "link" => link}) do
    icon_cdn = "#{@static_icon}/social/"
    gallery_social_icon_class = @class["gallery_social_icon"]

    ~s(<div class="#{gallery_social_icon_class}">
        <a href="#{link}">
          <svg>
            <image xlink:href="#{icon_cdn}#{name}.svg" />
          </svg>
        </a>
      </div>)
  end
end
