defmodule Helper.Sanitizer do
  @moduledoc """
  Sanitizer user input from editor.js or other
  content contains html tags
  see; http://katafrakt.me/2016/09/03/custom-rules-in-htmlsanitizeex/
  """
  defmodule Scrubber do
    @moduledoc false

    require HtmlSanitizeEx.Scrubber.Meta
    alias HtmlSanitizeEx.Scrubber.Meta

    Meta.remove_cdata_sections_before_scrub()
    Meta.strip_comments()

    Meta.allow_tag_with_uri_attributes("a", ["href"], ["http", "https"])
    Meta.allow_tag_with_these_attributes("a", ["name", "title"])

    # Meta.allow_tag_with_these_attributes("strong", [])
    # Meta.allow_tag_with_these_attributes("em", [])
    Meta.allow_tag_with_these_attributes("b", [])
    Meta.allow_tag_with_these_attributes("i", [])
    Meta.allow_tag_with_these_attributes("mark", ["class"])
    Meta.allow_tag_with_these_attributes("code", ["class"])
    # Meta.allow_tag_with_these_attributes("p", [])

    Meta.strip_everything_not_covered()
  end

  def sanitize(html) do
    html |> HtmlSanitizeEx.Scrubber.scrub(Scrubber)
  end
end
