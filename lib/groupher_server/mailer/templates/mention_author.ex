defmodule GroupherServer.Email.Templates.MentionAuthor do
  @moduledoc """
  template for mention author, like but not limit to:

  post, job, repo ...
  or mention in comment ..

  if you want change style or debug the template
  just copy and paste raw string to: https://mjml.io/try-it-live
  """

  def html(record) do
    """
    TODO
    """
  end

  def text() do
    """
    有人发帖了
    """
  end

  defp raw() do
    """
    <mjml>
    <mj-head>
    <mj-title>Discount Light</mj-title>
    <mj-preview>Pre-header Text</mj-preview>
    <mj-attributes>
      <mj-all font-family="'Helvetica Neue', Helvetica, Arial, sans-serif"></mj-all>
      <mj-text font-weight="400" font-size="16px" color="#000000" line-height="24px" font-family="'Helvetica Neue', Helvetica, Arial, sans-serif"></mj-text>
    </mj-attributes>
    <mj-style inline="inline">
      .body-section { -webkit-box-shadow: 1px 4px 11px 0px rgba(0, 0, 0, 0.15); -moz-box-shadow: 1px 4px 11px 0px rgba(0, 0, 0, 0.15); box-shadow: 1px 4px 11px 0px rgba(0, 0, 0, 0.15); }
    </mj-style>
    <mj-style inline="inline">
      .text-link { color: #5e6ebf }
    </mj-style>
    <mj-style inline="inline">
      .footer-link { color: #888888 }
    </mj-style>

    </mj-head>
    <mj-body background-color="#002B34" width="600px">
    <mj-section full-width="full-width" background-color="#183a42" padding-bottom="0">
      <mj-column width="100%">
        <mj-text color="#17CBC4" font-weight="bold" align="center" font-size="18px" letter-spacing="1px" padding-top="20px">
          coderplanets
          <br/>
        </mj-text>
        <mj-text color="#0d8396" align="center" font-size="13px" padding-top="0" font-weight="bold" letter-spacing="1px" line-height="20px">
          the most sexiest community for developers, ever.
        </mj-text>

      </mj-column>
    </mj-section>

    <mj-wrapper padding-top="0" padding-bottom="0" css-class="body-section">
      <mj-section background-color="#042f3a" padding-left="6px" padding-right="6px">
        <mj-column width="100%">
          <mj-text color="#6f8696" font-weight="bold" font-size="18px">
            <br/>
            xxx 在文章/评论标题里提及/回复了你
          </mj-text>
          <mj-text color="#637381" font-size="16px">
            文章内容或评论内容摘要
          </mj-text>

          <mj-divider border-width="1px" border-style="dashed" border-color="#113A41" />


          <mj-text color="#637381" font-size="16px" padding-top="10px" align="center">
            <a class="text-link" href="https://github.com/coderplanets.com">去看看 -></a>
          </mj-text>

        </mj-column>
      </mj-section>

    </mj-wrapper>

    <mj-wrapper full-width="full-width">
      <mj-section>
        <mj-column width="100%" padding="0">
          <mj-social font-size="15px" icon-size="30px" mode="horizontal" padding="0" align="center">
            <mj-social-element name="github" href="https://github.com/coderplanets" background-color="#296C7D">
            </mj-social-element>
          </mj-social>


          <mj-text color="#445566" font-size="11px" align="center" line-height="16px">
            &copy; Coderplanets Inc., All Rights Reserved.
          </mj-text>
        </mj-column>
      </mj-section>
      <mj-section padding-top="0">
        <mj-group>
          <mj-column width="100%" padding-right="0">
            <mj-text color="#445566" font-size="11px" align="center" line-height="16px" font-weight="bold">
              <a class="footer-link" href="https://coderplanets.com/home/post/45">Privacy</a>&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;<a class="footer-link" href="https://www.github.com/coderplanets/coderplanets_web/issues">Unsubscribe</a>
            </mj-text>
          </mj-column>
        </mj-group>

      </mj-section>
    </mj-wrapper>

    </mj-body>
    </mjml>
    """
  end
end
