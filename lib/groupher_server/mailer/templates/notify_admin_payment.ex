defmodule GroupherServer.Email.Templates.NotifyAdminPayment do
  @moduledoc """
  template for notify admin new register, if you want change style or debug the template
  just copy and paste raw string to: https://mjml.io/try-it-live
  """

  def html(record) do
    """
    <!doctype html>
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">

    <head>
    <title> coderplanets email </title>
    <!--[if !mso]><!-- -->
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <!--<![endif]-->
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style type="text/css">
    #outlook a {
      padding: 0;
    }

    .ReadMsgBody {
      width: 100%;
    }

    .ExternalClass {
      width: 100%;
    }

    .ExternalClass * {
      line-height: 100%;
    }

    body {
      margin: 0;
      padding: 0;
      -webkit-text-size-adjust: 100%;
      -ms-text-size-adjust: 100%;
    }

    table,
    td {
      border-collapse: collapse;
      mso-table-lspace: 0pt;
      mso-table-rspace: 0pt;
    }

    img {
      border: 0;
      height: auto;
      line-height: 100%;
      outline: none;
      text-decoration: none;
      -ms-interpolation-mode: bicubic;
    }

    p {
      display: block;
      margin: 13px 0;
    }
    </style>
    <!--[if !mso]><!-->
    <style type="text/css">
    @media only screen and (max-width:480px) {
      @-ms-viewport {
        width: 320px;
      }
      @viewport {
        width: 320px;
      }
    }
    </style>
    <!--<![endif]-->
    <!--[if mso]>
        <xml>
        <o:OfficeDocumentSettings>
          <o:AllowPNG/>
          <o:PixelsPerInch>96</o:PixelsPerInch>
        </o:OfficeDocumentSettings>
        </xml>
        <![endif]-->
    <!--[if lte mso 11]>
        <style type="text/css">
          .outlook-group-fix { width:100% !important; }
        </style>
        <![endif]-->
    <style type="text/css">
    @media only screen and (min-width:480px) {
      .mj-column-per-100 {
        width: 100% !important;
        max-width: 100%;
      }
    }
    </style>
    <style type="text/css">
    </style>
    </head>

    <body style="background-color:#002B34;">
    <div style="display:none;font-size:1px;color:#ffffff;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">有人捐助</div>
    <div style="background-color:#002B34;">
    <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="background:#183a42;background-color:#183a42;width:100%;">
      <tbody>
        <tr>
          <td>
            <!--[if mso | IE]>
      <table
         align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600"
      >
        <tr>
          <td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;">
      <![endif]-->
            <div style="Margin:0px auto;max-width:600px;">
              <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;">
                <tbody>
                  <tr>
                    <td style="direction:ltr;font-size:0px;padding:20px 0;padding-bottom:0;text-align:center;vertical-align:top;">
                      <!--[if mso | IE]>
                  <table role="presentation" border="0" cellpadding="0" cellspacing="0">

        <tr>

            <td
               class="" style="vertical-align:top;width:600px;"
            >
          <![endif]-->
                      <div class="mj-column-per-100 outlook-group-fix" style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;">
                        <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="vertical-align:top;" width="100%">
                          <tr>
                            <td align="center" style="font-size:0px;padding:10px 25px;padding-top:20px;word-break:break-word;">
                              <div style="font-family:'Helvetica Neue', Helvetica, Arial, sans-serif;font-size:18px;font-weight:bold;letter-spacing:1px;line-height:24px;text-align:center;color:#17CBC4;"> coderplanets <br> </div>
                            </td>
                          </tr>
                          <tr>
                            <td align="center" style="font-size:0px;padding:10px 25px;padding-top:0;word-break:break-word;">
                              <div style="font-family:'Helvetica Neue', Helvetica, Arial, sans-serif;font-size:13px;font-weight:bold;letter-spacing:1px;line-height:20px;text-align:center;color:#0d8396;"> 可能是最性感的开发者社区 <br> the most sexiest community for developers, ever. </div>
                            </td>
                          </tr>
                        </table>
                      </div>
                      <!--[if mso | IE]>
            </td>

        </tr>

                  </table>
                <![endif]-->
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <!--[if mso | IE]>
          </td>
        </tr>
      </table>
      <![endif]-->
          </td>
        </tr>
      </tbody>
    </table>
    <!--[if mso | IE]>
      <table
         align="center" border="0" cellpadding="0" cellspacing="0" class="body-section-outlook" style="width:600px;" width="600"
      >
        <tr>
          <td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;">
      <![endif]-->
    <div class="body-section" style="-webkit-box-shadow: 1px 4px 11px 0px rgba(0, 0, 0, 0.15); -moz-box-shadow: 1px 4px 11px 0px rgba(0, 0, 0, 0.15); box-shadow: 1px 4px 11px 0px rgba(0, 0, 0, 0.15); Margin: 0px auto; max-width: 600px;">
      <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;">
        <tbody>
          <tr>
            <td style="direction:ltr;font-size:0px;padding:20px 0;padding-bottom:0;padding-top:0;text-align:center;vertical-align:top;">
              <!--[if mso | IE]>
                  <table role="presentation" border="0" cellpadding="0" cellspacing="0">

            <tr>
              <td
                 class="" width="600px"
              >

      <table
         align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600"
      >
        <tr>
          <td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;">
      <![endif]-->
              <div style="background:#042f3a;background-color:#042f3a;Margin:0px auto;max-width:600px;">
                <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="background:#042f3a;background-color:#042f3a;width:100%;">
                  <tbody>
                    <tr>
                      <td style="direction:ltr;font-size:0px;padding:20px 0;text-align:center;vertical-align:top;">
                        <!--[if mso | IE]>
                  <table role="presentation" border="0" cellpadding="0" cellspacing="0">

        <tr>

            <td
               class="" style="vertical-align:top;width:600px;"
            >
          <![endif]-->
                        <div class="mj-column-per-100 outlook-group-fix" style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;">
                          <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="vertical-align:top;" width="100%">
                            <tr>
                              <td align="center" style="font-size:0px;padding:10px 25px;word-break:break-word;">
                                <div style="font-family:'Helvetica Neue', Helvetica, Arial, sans-serif;font-size:18px;font-weight:bold;line-height:24px;text-align:center;color:#6f8696;"> # 好心人打赏 #{
      record.amount
    } 元 # </div>
                              </td>
                            </tr>
                            <tr>
                              <td style="font-size:0px;padding:10px 25px;word-break:break-word;">
                                <p style="border-top:dashed 1px #002F39;font-size:1;margin:0px auto;width:100%;"> </p>
                                <!--[if mso | IE]>
        <table
           align="center" border="0" cellpadding="0" cellspacing="0" style="border-top:dashed 1px #002F39;font-size:1;margin:0px auto;width:550px;" role="presentation" width="550px"
        >
          <tr>
            <td style="height:0;line-height:0;">
              &nbsp;
            </td>
          </tr>
        </table>
      <![endif]-->
                              </td>
                            </tr>
                            <tr>
                              <td align="left" style="font-size:0px;padding:10px 25px;word-break:break-word;">
                                <table cellpadding="0" cellspacing="0" width="100%" border="0" style="cellspacing:0;color:#6C8695;font-family:'Helvetica Neue', Helvetica, Arial, sans-serif;font-size:18px;line-height:40px;table-layout:auto;width:100%;">
                                  <tr style="border-top:1px solid #6C8695;text-align:left;">
                                    <th style="padding: 0 15px;">账单 ID</th>
                                    <th style="padding: 0 0 0 15px;">#{record.id}</th>
                                  </tr>
                                  <tr style="border-top:1px solid #6C8695;text-align:left;">
                                    <td style="padding: 0 15px;">用户 ID</td>
                                    <td style="padding: 0 0 0 15px;">#{record.user_id}</td>
                                  </tr>
                                  <tr style="border-top:1px solid #6C8695;text-align:left;">
                                    <td style="padding: 0 15px;">留言</td>
                                    <td style="padding: 0 0 0 15px;">#{record.note}</td>
                                  </tr>
                                  <tr style="border-top:1px solid #6C8695;text-align:left;">
                                    <td style="padding: 0 15px;">打赏方式</td>
                                    <td style="padding: 0 0 0 15px;">#{record.payment_method}</td>
                                  </tr>
                                  <tr style="border-top:1px solid #6C8695;text-align:left;">
                                    <td style="padding: 0 15px;">打赏用途</td>
                                    <td style="padding: 0 0 0 15px;">#{record.payment_usage}</td>
                                  </tr>
                                  <tr style="border-top:1px solid #6C8695;text-align:left;">
                                    <td style="padding: 0 15px;">打赏时间</td>
                                    <td style="padding: 0 0 0 15px;">#{record.inserted_at}</td>
                                  </tr>
                                </table>
                              </td>
                            </tr>
                          </table>
                        </div>
                        <!--[if mso | IE]>
            </td>

        </tr>

                  </table>
                <![endif]-->
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <!--[if mso | IE]>
          </td>
        </tr>
      </table>

              </td>
            </tr>

                  </table>
                <![endif]-->
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <!--[if mso | IE]>
          </td>
        </tr>
      </table>
      <![endif]-->
    <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;">
      <tbody>
        <tr>
          <td>
            <!--[if mso | IE]>
      <table
         align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600"
      >
        <tr>
          <td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;">
      <![endif]-->
            <div style="Margin:0px auto;max-width:600px;">
              <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;">
                <tbody>
                  <tr>
                    <td style="direction:ltr;font-size:0px;padding:20px 0;text-align:center;vertical-align:top;">
                      <!--[if mso | IE]>
                  <table role="presentation" border="0" cellpadding="0" cellspacing="0">

            <tr>
              <td
                 class="" width="600px"
              >

      <table
         align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600"
      >
        <tr>
          <td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;">
      <![endif]-->
                      <div style="Margin:0px auto;max-width:600px;">
                        <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;">
                          <tbody>
                            <tr>
                              <td style="direction:ltr;font-size:0px;padding:20px 0;text-align:center;vertical-align:top;">
                                <!--[if mso | IE]>
                  <table role="presentation" border="0" cellpadding="0" cellspacing="0">

        <tr>

            <td
               class="" style="vertical-align:top;width:600px;"
            >
          <![endif]-->
                                <div class="mj-column-per-100 outlook-group-fix" style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;">
                                  <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                    <tbody>
                                      <tr>
                                        <td style="vertical-align:top;padding:0;">
                                          <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="" width="100%">
                                            <tr>
                                              <td align="center" style="font-size:0px;padding:0;word-break:break-word;">
                                                <!--[if mso | IE]>
      <table
         align="center" border="0" cellpadding="0" cellspacing="0" role="presentation"
      >
        <tr>

              <td>
            <![endif]-->
                                                <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="float:none;display:inline-table;">
                                                  <tr>
                                                    <td style="padding:4px;">
                                                      <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="background:#296C7D;border-radius:3px;width:30px;">
                                                        <tr>
                                                          <td style="font-size:0;height:30px;vertical-align:middle;width:30px;"> <a href="https://mjml.io/" target="_blank">
                    <img height="30" src="https://www.mailjet.com/images/theme/v1/icons/ico-social/github.png" style="border-radius:3px;" width="30">
                  </a> </td>
                                                        </tr>
                                                      </table>
                                                    </td>
                                                  </tr>
                                                </table>
                                                <!--[if mso | IE]>
              </td>

          </tr>
        </table>
      <![endif]-->
                                              </td>
                                            </tr>
                                            <tr>
                                              <td align="center" style="font-size:0px;padding:10px 25px;word-break:break-word;">
                                                <div style="font-family:'Helvetica Neue', Helvetica, Arial, sans-serif;font-size:11px;font-weight:400;line-height:16px;text-align:center;color:#445566;"> &copy; Coderplanets Inc., All Rights Reserved. </div>
                                              </td>
                                            </tr>
                                          </table>
                                        </td>
                                      </tr>
                                    </tbody>
                                  </table>
                                </div>
                                <!--[if mso | IE]>
            </td>

        </tr>

                  </table>
                <![endif]-->
                              </td>
                            </tr>
                          </tbody>
                        </table>
                      </div>
                      <!--[if mso | IE]>
          </td>
        </tr>
      </table>

              </td>
            </tr>

            <tr>
              <td
                 class="" width="600px"
              >

      <table
         align="center" border="0" cellpadding="0" cellspacing="0" class="" style="width:600px;" width="600"
      >
        <tr>
          <td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;">
      <![endif]-->
                      <div style="Margin:0px auto;max-width:600px;">
                        <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;">
                          <tbody>
                            <tr>
                              <td style="direction:ltr;font-size:0px;padding:20px 0;padding-top:0;text-align:center;vertical-align:top;">
                                <!--[if mso | IE]>
                  <table role="presentation" border="0" cellpadding="0" cellspacing="0">

        <tr>

            <td
               class="" style="width:600px;"
            >
          <![endif]-->
                                <div class="mj-column-per-100 outlook-group-fix" style="font-size:0;line-height:0;text-align:left;display:inline-block;width:100%;direction:ltr;">
                                  <!--[if mso | IE]>
        <table  role="presentation" border="0" cellpadding="0" cellspacing="0">
          <tr>

              <td
                 style="vertical-align:top;width:600px;"
              >
              <![endif]-->
                                  <div class="mj-column-per-100 outlook-group-fix" style="font-size:13px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;">
                                    <table border="0" cellpadding="0" cellspacing="0" role="presentation" width="100%">
                                      <tbody>
                                        <tr>
                                          <td style="vertical-align:top;padding-right:0;">
                                            <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="" width="100%">
                                              <tr>
                                                <td align="center" style="font-size:0px;padding:10px 25px;word-break:break-word;">
                                                  <div style="font-family:'Helvetica Neue', Helvetica, Arial, sans-serif;font-size:11px;font-weight:bold;line-height:16px;text-align:center;color:#445566;"> <a class="footer-link" href="https://coderplanets.com/home/post/45" style="color: #888888;">Privacy</a>&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;<a class="footer-link" href="https://www.github.com/coderplanets/coderplanets_web/issues"
                                                      style="color: #888888;">Unsubscribe</a> </div>
                                                </td>
                                              </tr>
                                            </table>
                                          </td>
                                        </tr>
                                      </tbody>
                                    </table>
                                  </div>
                                  <!--[if mso | IE]>
              </td>

          </tr>
          </table>
        <![endif]-->
                                </div>
                                <!--[if mso | IE]>
            </td>

        </tr>

                  </table>
                <![endif]-->
                              </td>
                            </tr>
                          </tbody>
                        </table>
                      </div>
                      <!--[if mso | IE]>
          </td>
        </tr>
      </table>

              </td>
            </tr>

                  </table>
                <![endif]-->
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <!--[if mso | IE]>
          </td>
        </tr>
      </table>
      <![endif]-->
          </td>
        </tr>
      </tbody>
    </table>
    </div>
    </body>

    </html>

    """
  end

  def text() do
    """
    有人打赏了
    """
  end

  defp raw() do
    """
    <mjml>
      <mj-head>
        <mj-title>coderplanets email</mj-title>
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
              可能是最性感的开发者社区
              <br/> the most sexiest community for developers, ever.
            </mj-text>

          </mj-column>
        </mj-section>

        <mj-wrapper padding-top="0" padding-bottom="0" css-class="body-section">
          <mj-section background-color="#042f3a">

            <mj-column width="100%">
              <mj-text color="#6f8696" align="center" font-weight="bold" font-size="18px">
              # 好心人打赏 xxx 元 #
              </mj-text>
              <mj-divider border-width="1px" border-style="dashed" border-color="#002F39" />
              <mj-table color="#6C8695" font-size="18px" line-height="40px">
                <tr style="border-top:1px solid #6C8695;text-align:left;">
                  <th style="padding: 0 15px;">账单 ID</th>
                  <th style="padding: 0 0 0 15px;">733</th>
                </tr>
                <tr style="border-top:1px solid #6C8695;text-align:left;">
                  <td style="padding: 0 15px;">用户 ID</td>
                  <td style="padding: 0 0 0 15px;">345k5</td>
                </tr>
                <tr style="border-top:1px solid #6C8695;text-align:left;">
                  <td style="padding: 0 15px;">留言</td>
                  <td style="padding: 0 0 0 15px;">note</td>
                </tr>
                <tr style="border-top:1px solid #6C8695;text-align:left;">
                  <td style="padding: 0 15px;">打赏方式</td>
                  <td style="padding: 0 0 0 15px;">alipay</td>
                </tr>
                <tr style="border-top:1px solid #6C8695;text-align:left;">
                  <td style="padding: 0 15px;">打赏用途</td>
                  <td style="padding: 0 0 0 15px;">donate</td>
                </tr>
                <tr style="border-top:1px solid #6C8695;text-align:left;">
                  <td style="padding: 0 15px;">打赏时间</td>
                  <td style="padding: 0 0 0 15px;">2018/05/24 03:22</td>
                </tr>
              </mj-table>

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
