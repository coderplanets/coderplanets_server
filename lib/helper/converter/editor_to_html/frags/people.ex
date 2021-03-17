defmodule Helper.Converter.EditorToHTML.Frags.People do
  @moduledoc """
  parse editor.js's block fragments, use for test too

  see https://editorjs.io/
  """
  import Helper.Utils, only: [get_config: 2]

  alias Helper.Converter.EditorToHTML.Class
  alias Helper.Types, as: T

  @static_icon  get_config(:cloud_assets, :static_icon)
  @class get_in(Class.article(), ["people"])

  @spec get_card(:gallery, T.editor_people_item()) :: T.html()
  def get_card(:gallery, %{
        # "id" => _id,
        "avatar" => avatar,
        "title" => title,
        "bio" => bio,
        "desc" => desc,
        "socials" => socials
      }) do
    # classes
    gallery_card_wrapper_class = @class["gallery_card_wrapper"]
    gallery_avatar_class = @class["gallery_avatar"]
    gallery_intro_class = @class["gallery_intro"]
    gallery_intro_title_class = @class["gallery_intro_title"]
    gallery_intro_bio_class = @class["gallery_intro_bio"]
    gallery_intro_desc_class = @class["gallery_intro_desc"]

    social_wrapper_class = @class["gallery_social_wrapper"]
    social_content = frag(socials)

    ~s(<div class="#{gallery_card_wrapper_class}">
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
          #{social_content}
         </div>
      </div>)
  end

  defp frag(socials) do
    icon_cdn = "#{@static_icon}/social/"

    gallery_social_wrapper_class = @class["gallery_social_wrapper"]
    gallery_social_icon_class = @class["gallery_social_icon"]

    social_content =
      Enum.reduce(socials, "", fn social, acc ->
        link = social["link"]
        name = social["name"]

        icon_html = ~s(
            <div class="#{gallery_social_icon_class}">
              <a href="#{link}">
                <svg>
                  <image xlink:href="#{icon_cdn}#{name}.svg" />
                </svg>
              </a>
            </div>
          )
        acc <> icon_html
      end)

    ~s(
      <div class="#{gallery_social_wrapper_class}">
         #{social_content}
      </div>
    )
  end
end
