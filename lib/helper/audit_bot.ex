defmodule Helper.AuditBot do
  @moduledoc """
  敏感词检测服务

  # see more details in doc https://ai.baidu.com/ai-doc/ANTIPORN/Nk3h6xbb2

  return example

  give text = "<div>M卖批, 这也太操蛋了, 党中央</div>"

  got

  %{
    illegal_reason: ["政治敏感", "低俗辱骂"],
    illegal_words: ["党中央", "操蛋", "卖批"],
    is_legal: false
    audit_failed: false
    audit_failed_reason: ""
  }
  """
  use Tesla, only: [:post]
  import Helper.Utils, only: [get_config: 2]

  @timeout_limit 4000

  plug(Tesla.Middleware.Headers, [{"Content-Type", "application/x-www-form-urlencoded"}])
  plug(Tesla.Middleware.Retry, delay: 300, max_retries: 3)
  plug(Tesla.Middleware.Timeout, timeout: @timeout_limit)
  plug(Tesla.Middleware.FormUrlencoded)

  # conclusionType === 1
  @conclusionOK 1
  @conclusionMaybe 3

  # @token get_config(:audit, :token)

  @url "https://aip.baidubce.com"
  # @endpoint "#{@url}/rest/2.0/solution/v1/text_censor/v2/user_defined?access_token=#{@token}"
  @wrong_endpoint "#{@url}/rest/2.0/solution/v1/text_censor/v2/user_defined?access_token=wrong"

  def analysis(:text, text) do
    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    query = %{
      text: text |> HtmlSanitizeEx.strip_tags()
    }

    with {:ok, result} <- post(get_endpoint(), query) do
      parse_result(result)
    end
  end

  def analysis_wrong(:text, text) do
    query = %{
      text: text |> HtmlSanitizeEx.strip_tags()
    }

    with {:ok, result} <- post(@wrong_endpoint, query) do
      parse_result(result)
    end
  end

  defp parse_result(%Tesla.Env{body: body, status: 200}) do
    with {:ok, result} <- Jason.decode(body),
         {:ok, result} <- is_request_ok?(result) do
      conclusion = result["conclusionType"]

      case conclusion === @conclusionOK or conclusion === @conclusionMaybe do
        true ->
          {:ok,
           %{
             is_legal: true,
             illegal_reason: [],
             illegal_words: [],
             audit_failed: false,
             audit_failed_reason: ""
           }}

        false ->
          parse_illegal(result)
      end
    else
      error -> error
    end
  end

  defp is_request_ok?(%{"error_code" => _error_code, "error_msg" => error_msg}) do
    {:error,
     %{
       is_legal: true,
       illegal_reason: [],
       illegal_words: [],
       audit_failed: true,
       audit_failed_reason: error_msg
     }}
  end

  defp is_request_ok?(result), do: {:ok, result}

  defp parse_illegal(result) do
    data = result["data"]

    {:error,
     %{
       is_legal: false,
       illegal_reason: gather_reason(data),
       illegal_words: gather_keyworks(data),
       audit_failed: false,
       audit_failed_reason: ""
     }}
  end

  defp gather_reason(data) do
    data
    |> Enum.reduce([], fn item, acc ->
      reason = item["subType"] |> transSubType
      acc ++ [reason]
    end)
  end

  defp gather_keyworks(data) do
    data
    |> Enum.reduce([], fn item, acc ->
      words = gather_hits(item["hits"])
      acc ++ words
    end)
  end

  defp gather_hits(hits) do
    hits
    |> Enum.reduce([], fn hit, acc ->
      acc ++ hit["words"]
    end)
    |> Enum.uniq()
  end

  defp transSubType(0), do: "低质灌水"
  defp transSubType(1), do: "暴恐违禁"
  defp transSubType(2), do: "文本色情"
  defp transSubType(3), do: "政治敏感"
  defp transSubType(4), do: "恶意 / 软文推广"
  defp transSubType(5), do: "低俗辱骂"
  defp transSubType(6), do: "恶意 / 软文推广"
  defp transSubType(7), do: "恶意 / 软文推广"
  defp transSubType(8), do: "恶意 / 软文推广"
  defp transSubType(_), do: "疑似灌水"

  defp get_endpoint() do
    token = get_config(:audit, :token)
    "#{@url}/rest/2.0/solution/v1/text_censor/v2/user_defined?access_token=#{token}"
  end

  def test() do
    text = """
    <div class="article-viewer-wrapper"><h2 id="block-h5nAl">关于产品</h2><p id="block-ADGMH">CoderPlanets 是一个开源的、面向  IT 垂直领域的中文社区平台，提供类似于 Reddit 社区，ProductHunt 作品发布，Medium 博客平台以及各种自以为是的、奇奇怪怪的服务。</p><h2 id="block-6LrrL">关于为什么</h2><h3 id="block-D4y6q">1. 为什么是社区？</h3><p id="block-ktgV6">中文社区，尤其是技术社区的现状和一些平台各种让人窒息的骚操作我就不赘述了，这几年关注产品多一些，心中渐渐升起一轮疑问：中国的 Reddit, ProductHunt, Medium 们怎么都没有做起来（如果曾经有的话）？</p><p id="block-Zb6Pc">我平时喜欢踢球，有时候觉得中文社区很多现象和中国足球还挺像的 — 足协监管不行，教练不行，草皮不行，球迷文化不行，市场环境不行，日韩崛起之前黄种人也不行，总之各种大字报式的不得行，就是没人说技战术本身，时至今日国足都被越南按着摩擦了，不缺技术缺的是xx（可能是钙?）的论调依然充斥耳边。</p><p id="block-PAONM">纯主观感受，Github, StackOverflow, HN, Reddit, Medium, ProductHunt, IndieHackers, Dev.to, Discord 哪怕是 Discourse / Flarum , 这些外网常见的开发者交流平台，在国内真的很少有在产品力和情怀上能与之接近的产品。除了足协和草皮之外，有没有可能，我只是说有可能（音量 0.5%），<b>我们本身的产品力不够好？</b>Github 不仅只是一个简单的托管平台，他本身优秀的设计就大大促进了开源运动的推广和发展，更像是一种共生关系。</p><p id="block-HGMHN">产品力不够的情况下一味去“运营推广”，我不否认这很重要，但这总会让我联想起国足明明技战术水平不行，总爱强调个精神意志力一样，挨打不立正，[不能说没道理，但就是怪怪的].jpg。</p><p id="block-vIS4g">所以为什么是社区？我想尝试一个最朴素而真诚的想法：通过认真把社区产品本身打磨好（当然目前还差的很远），剧情的发展会不会有一些不同？</p><p id="block-FV84Y">退两步从现实角度来说，根据上个月 Github 公布的数据，仅来自国内的注册用户就已经超过了 755 万，如此庞大的开发者群体，口味一定是多种多样的，参差多态乃幸福本源，谁也不希望出去外面吃饭，街上只有一两家餐厅可供选择吧？</p><h3 id="block-BDEEe">2. 为什么是中文?</h3><p id="block-PiHru">因为是母语啊。文字之间，很多时候是很难用非母语去交流的，这里语境的交流，不是指能看懂文档、README，能提 issue 或者参与 StackOverflow 之类说明书式的、功能性的交流，而是指那种能浸润情感的，见梗会意一目 n 行的，有幽默感的那种，哦，正常交流 。。不长期浸淫双方的文化背景，这其实是非常困难的。很多时候我们只是单向的被辐射。</p><p id="block-zIPK1">国内技术圈子时不时有种莫名其妙的、动辄鄙视用中文交流的政治正确，有些人，那确实是猛龙过江学贯中西咱服了，但也有些人，等慕名顺着网线去拜读他们在外网的 Post，会发现很多就停留在手语比划的层面，整个感觉和商场里那种导航机器人差不多，其实挺没劲的，无聊的要死。</p><p id="block-epOV2">往狭义上杠，这些叫沟通，不是交流。语言文字远不仅仅只是所谓的“沟通的工具”，这种不知道哪儿冒出来的言论实在是太过贬低了。</p><p id="block-1Q0Rg">隔行不隔理。自己的联赛、青训拉跨，整体上竞技水平是不可能高的，这是普世性的基础共识，不是简单的请进派出几个大V就能解决，更不是谩骂抱怨能改善的。自嘲自黑无法赢得尊重。环境的改变不能只靠羊教练，大头还得是基层的组织参与，训练比赛的日常点滴等等。当然这跑题了。。</p><h2 id="block-A21M8">关于域名</h2><p id="block-LLzRj">我是一个三体迷，对宇宙中的各种都市传说感兴趣。planets 这个域名是我在 N 刷 《星际穿越》的间隙阴差阳错捡来的（虽然后来我确实花了很多心思在网站上加入了<a href="https://coderplanets.com/post/254">各种宇宙元素</a>），并没有什么深思熟虑，也不是要模仿谁。</p><p id="block-SkU1G">域名，尤其是有意义的短域名，是非常稀缺的资源，选择一个两个单词组合的长域名也确实存在客观条件的限制。所以为了方便各位“懒人”，也同时启用了一个好记的短域名：cper.co, ，目前用在站内文章的分享模块。</p><h2 id="block-iFFdD">关于合规</h2><p id="block-MBZzl">社区平台模式在国内几乎是个“伏地魔”一般的话题，说起来都是闻风丧胆，但实际见过做过的人却又少的可怜，问就是有个朋友语焉不详。真正的参与者因为某些原因似乎也比较避讳这个话题 -- 至少我发给各大社区的咨询邮件都石沉大海了。。</p><p id="block-GqiwN">言论的管制当然会降低讨论话题的多样性和深度，就好比在路上开车，谁也不会到红灯底下才瞬间停止，都是老远就踩了刹车。但是随着年龄和阅历的增长，我也能渐渐理解这种做法，这并不是简单的非黑即白的事情，有各方面的因素。</p><p id="block-tuGyu">垂直领域的社区情况要好一些，公司、ICP 备案、敏感词检测该有的都有，其他证件资质在目前还不需要，需要我也会尽快补齐，这其中的经验过程都会同步到社区中以供参考，就不展开了。</p><h2 id="block-rU3Hd">关于盈利</h2><p id="block-op94B">CP 从产品形态上借鉴了很多 Reddit 的元素，但在盈利模式上更向往 “Medium” 的 membership / SaaS、或 “Shopify” 那种工具文化的模式。</p><p id="block-GoqPt">传统的外挂式自动化广告对于文字类网站的体验降维是灾难性的 — 想象一下你在一家装修精美的餐厅（比如 Medium）正在享受晚餐（阅读技术资料），旁边突然有个油嘴滑舌的房产中介向你喋喋不休（侧边栏设计拙劣的双十一服务器广告传单）是什么体验？是，你可以选择带上降噪耳机（AdBlock）不去看 Ta，继续用餐，但问题的源头是，这家餐厅为什么要允许这些人进来发传单？ 我又为什么要忍受这样糟糕的服务？</p><p id="block-dhtZm">p.s: 我对房产中介没有不敬的意思，只是打个比喻。也顺便说一下 AdBlock 不违法，但是很不道德。至于说餐厅是收费的网站是免费的，你可以把餐厅的比喻换成书店之类的场所，这就不重复了，不是重点。</p><p id="block-Gh9PA">Medium 作为北美流量前 20 的网站，你很难在上面看到像国内网站那种塞满屏幕的传单式广告，相反它排版优雅大量留白、专注阅读本身的体验，Shopify 那种美好的工具文化的产物就更不用说了。</p><p id="block-PUF4U">我想表达的是，盈利模式在很大程度上会影响产品形态和用户体验。广告模式是广泛存在，但它未必是合理的、适合所有场景的，互联网并不是只有靠广告收益才能生存，至少 Medium 和 Shopify 证明了还有其他的被主流市场验证过的路可以尝试。</p><p id="block-DX4Pn">CoderPlanets 既是提供社区服务的平台，本身也是建立社区的工具。</p><h2 id="block-euCjx">关于团队</h2><p id="block-lT96O">目前团队在产品开发上只有我一人。 不过得益于现在基础设施、开发工具和资源的成熟丰富，对于 CRUD 层面的工作，一个人也可以做到所谓的“全栈”，具体到社区这种周期很长的项目上，前期人少倒也不是坏事 — 回头来看，很多想法初期其实是非常模糊的，是在做的过程中才慢慢连点成线，逐渐变的清晰起来，这个过程需要时间反复的打磨，通常还伴随着破坏性的重构，用传统的产品-设计-开发那种“下周发版”的流水线搞法，几乎注定扑街，沟通成本真的是非常大的成本。缺点就是慢，望山跑死马，需要足够的耐心、体力和相信自己的直觉。。</p><p id="block-bXc9t">目前项目已经度过前期从 0 到 1，虽然技术产品等各方面框架趋于清晰，但各种细节，内容和管理后勤支撑等方面还有大量工作量 ，如果你对社区的产品形态，技术，设计，维护治理等方面感兴趣，欢迎各种形式的参与。</p><h2 id="block-mrk3D">开放透明</h2><p id="block-38w1U">本站除源代码开源在 <a href="https://github.com/coderplanets">Github</a> 上以外，<a href="https://plausible.io/coderplanets.com">流量统计数据</a>也是完全公开的。同时，借鉴真实世界的运行模式，每个子社区都采用志愿者协助的自治模式 -- 细节很多，这里就不展开了。</p><p id="block-2zKdQ">p.s: 流量统计采用的服务商是开源的，对隐私友好的 <a href="https://plausible.io/">Plausible</a> ，它同样使用了小众的 Elixir 开发，我在项目上借鉴过它的一些写法。</p><h2 id="block-WdDFN">发展规划</h2><p id="block-exhYo">最迫切的就是收集各位用户的反馈建议，大的方向是社区的 SaaS 化和工具化。需要说明的是，所有的产品设计都是围绕专业的垂直领域需求而展开的，过去现在和未来都不会面向所有人，我没有那个技术、资源以及意愿。</p><p id="block-nQEBJ">目前这个项目有很多部分还是半成品，TodoList 上更是有接近 4 位数的细节条目等待完成，因此至少到年前，都会处于一个忙碌的修修补补的状态。</p><p id="block-K1vzO">最后，Designing a product from scratch is always hard. 也许再挺不了几年，也许经常会被打脸，但这就是我此时此刻，作为基层代码工人，近年来对社区论坛这个”古董概念”的一些不成熟的想法、摸索和实践。项目中未完成和闭门造车的地方一言难尽，期待能和大家一起讨论完善。</p></div>
    """

    analysis(:text, text)
  end
end
