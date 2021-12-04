defmodule GroupherServer.CMS.Delegate.Seeds.Tags do
  @moduledoc """
  tags seeds
  """

  alias GroupherServer.CMS
  alias CMS.Model.Community

  @tag_colors ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink", "grey"]

  def random_color(), do: @tag_colors |> Enum.random() |> String.to_atom()

  def get(_, :map, _), do: []
  def get(_, :cper, _), do: []
  def get(_, :setting, _), do: []
  def get(_, :team, _), do: []
  def get(_, :kanban, _), do: []
  def get(_, :works, _), do: []
  def get(_, :interview, _), do: []

  ## 首页 start

  @doc "post thread of HOME community"
  def get(_, :post, :home) do
    [
      %{
        title: "求助",
        raw: "help",
        group: "技术与人文"
      },
      %{
        raw: "tech",
        title: "技术",
        group: "技术与人文"
      },
      %{
        raw: "maker",
        title: "创作者",
        group: "技术与人文"
      },
      %{
        raw: "geek",
        title: "极客",
        group: "技术与人文"
      },
      %{
        raw: "IxD",
        title: "交互设计",
        group: "技术与人文"
      },
      %{
        raw: "DF",
        title: "黑暗森林",
        group: "技术与人文"
      },
      %{
        raw: "thoughts",
        title: "迷思",
        group: "技术与人文"
      },
      %{
        raw: "city",
        title: "城市",
        group: "生活与职场"
      },
      %{
        raw: "pantry",
        title: "茶水间",
        group: "生活与职场"
      },
      %{
        raw: "afterwork",
        title: "下班后",
        group: "生活与职场"
      },
      %{
        raw: "WTF",
        title: "吐槽",
        group: "其他"
      },
      %{
        raw: "REC",
        title: "推荐",
        group: "其他"
      },
      %{
        raw: "idea",
        title: "脑洞",
        group: "其他"
      },
      %{
        raw: "feedback",
        title: "站务",
        group: "其他"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end

  def get(_, :radar, :home) do
    [
      %{
        title: "语言 & 框架",
        raw: "tools"
      },
      %{
        title: "业界",
        raw: "industry"
      },
      %{
        title: "硬件",
        raw: "hardware"
      },
      %{
        title: "人工智能",
        raw: "ai"
      },
      %{
        title: "黑暗森林",
        raw: "security"
      },
      %{
        title: "融资 & 并购",
        raw: "finace"
      },
      %{
        title: "黑科技",
        raw: "edge"
      },
      %{
        title: "数据",
        raw: "number"
      },
      %{
        title: "言论",
        raw: "opinion"
      },
      %{
        title: "奇奇怪怪",
        raw: "others"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :radar, color: random_color()}, attr) end)
  end

  def get(_, :blog, :home) do
    [
      %{
        title: "前端",
        raw: "web"
      },
      %{
        title: "后端开发",
        raw: "backend"
      },
      %{
        title: "apple",
        raw: "apple"
      },
      %{
        title: "Android",
        raw: "android"
      },
      %{
        title: "设计",
        raw: "design"
      },
      %{
        title: "架构",
        raw: "arch"
      },
      %{
        title: "人工智能",
        raw: "ai"
      },
      %{
        title: "运营",
        raw: "growth"
      },
      %{
        title: "生活",
        raw: "life"
      },
      %{
        title: "其他",
        raw: "others"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :radar, color: random_color()}, attr) end)
  end

  def get(_, :job, :home) do
    [
      %{
        raw: "beijing",
        title: "北京",
        group: "城市"
      },
      %{
        raw: "shanghai",
        title: "上海",
        group: "城市"
      },
      %{
        raw: "hangzhou",
        title: "杭州",
        group: "城市"
      },
      %{
        raw: "shenzhen",
        title: "深圳",
        group: "城市"
      },
      %{
        raw: "guangzhou",
        title: "广州",
        group: "城市"
      },
      %{
        raw: "wuhan",
        title: "武汉",
        group: "城市"
      },
      %{
        raw: "chengdu",
        title: "成都",
        group: "城市"
      },
      %{
        raw: "xian",
        title: "西安",
        group: "城市"
      },
      %{
        raw: "xiamen",
        title: "厦门",
        group: "城市"
      },
      %{
        raw: "oversea",
        title: "海外",
        group: "城市"
      },
      %{
        raw: "remote",
        title: "远程",
        group: "城市"
      },
      %{
        raw: "others",
        title: "其他",
        group: "城市"
      },
      %{
        raw: "frontend",
        title: "前端",
        group: "职位"
      },
      %{
        raw: "backend",
        title: "后端开发",
        group: "职位"
      },
      %{
        raw: "mobile",
        title: "移动端",
        group: "职位"
      },
      %{
        raw: "ai",
        title: "人工智能",
        group: "职位"
      },
      %{
        raw: "devops",
        title: "DevOps",
        group: "职位"
      },
      %{
        raw: "securty",
        title: "安全",
        group: "职位"
      },
      %{
        raw: "others",
        title: "其他",
        group: "职位"
      },
      %{
        raw: "0-10k",
        title: "0-10k",
        group: "薪资范围"
      },
      %{
        raw: "10k-20k",
        title: "10k-20k",
        group: "薪资范围"
      },
      %{
        raw: "20k-40k",
        title: "20k-40k",
        group: "薪资范围"
      },
      %{
        raw: "40k-more",
        title: "40k 以上",
        group: "薪资范围"
      },
      %{
        raw: "negotiable",
        title: "面谈",
        group: "薪资范围"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :job, color: random_color()}, attr) end)
  end

  ## 首页 end

  ## Blackhole
  def get(_, :post, :blackhole) do
    [
      %{
        title: "传单",
        raw: "flyers"
      },
      %{
        title: "标题党",
        raw: "clickbait"
      },
      %{
        title: "封闭平台",
        raw: "ugly"
      },
      %{
        title: "盗版 & 侵权",
        raw: "pirate"
      },
      %{
        title: "水贴",
        raw: "cheat"
      },
      %{
        title: "无法无天",
        raw: "law"
      },
      %{
        title: "其他",
        raw: "others"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end

  def get(_, :account, :blackhole) do
    [
      %{
        title: "发传单",
        raw: "flyers"
      },
      %{
        title: "负能量",
        raw: "negative"
      },
      %{
        title: "滥用权限",
        raw: "ugly"
      },
      %{
        title: "无法无天",
        raw: "law"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :account, color: random_color()}, attr) end)
  end

  ## Blackhole end

  ## Feedback
  def get(_, :post, :feedback) do
    [
      %{
        title: "Bug",
        raw: "bug",
        group: "产品"
      },
      %{
        title: "功能建议",
        raw: "demand",
        group: "产品"
      },
      %{
        title: "内容审核",
        raw: "audit",
        group: "产品"
      },
      %{
        title: "编辑器",
        raw: "editor",
        group: "产品"
      },
      %{
        title: "界面交互",
        raw: "UI/UX",
        group: "产品"
      },
      %{
        title: "社区治理",
        raw: "manage",
        group: "产品"
      },
      %{
        title: "规章指南",
        raw: "intro",
        group: "其他"
      },
      %{
        title: "周报",
        raw: "devlog",
        group: "其他"
      },
      %{
        title: "其他",
        raw: "others",
        group: "其他"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end

  def get(_, :roadmap, :feedback), do: []

  def get(_, :account, :blackhole) do
    [
      %{
        title: "发传单",
        raw: "flyers"
      },
      %{
        title: "负能量",
        raw: "negative"
      },
      %{
        title: "滥用权限",
        raw: "ugly"
      },
      %{
        title: "无法无天",
        raw: "law"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :account, color: random_color()}, attr) end)
  end

  ## Feedback end

  ## 城市
  def get(_, :post, :city) do
    [
      %{
        title: "打听",
        raw: "ask"
      },
      %{
        title: "讨论",
        raw: "hangout"
      },
      %{
        title: "下班后",
        raw: "afterwork"
      },
      %{
        title: "推荐",
        raw: "REC"
      },
      %{
        title: "二手",
        raw: "trade"
      },
      %{
        title: "小聚",
        raw: "meetup"
      },
      %{
        title: "吐槽",
        raw: "WTF"
      },
      %{
        title: "求/转/合租",
        raw: "rent"
      },
      %{
        title: "奇奇怪怪",
        raw: "others"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :radar, color: random_color()}, attr) end)
  end

  def get(_, :job, :city) do
    get(:ignore, :job, :home) |> Enum.reject(&(&1.group in ["城市"]))
  end

  ## 城市 end

  ## 语言与框架
  def get(_, :post, :pl), do: get(:ignore, :post, :framework)

  def get(_, :post, :framework) do
    [
      %{
        title: "求助",
        raw: "help",
        group: "技术与工程"
      },
      %{
        title: "分享推荐",
        raw: "REC",
        group: "技术与工程"
      },
      %{
        title: "讨论",
        raw: "discuss",
        group: "技术与工程"
      },
      %{
        title: "学习资源",
        raw: "tuts",
        group: "技术与工程"
      },
      %{
        title: "小聚",
        raw: "meetup",
        group: "其他"
      },
      %{
        title: "杂谈",
        raw: "others",
        group: "其他"
      },
      %{
        title: "社区事务",
        raw: "routine",
        group: "其他"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end

  def get(_, :radar, :pl), do: get(:ignore, :radar, :framework)
  def get(_, :radar, :devops), do: get(:ignore, :radar, :framework)

  def get(_, :radar, :framework) do
    [
      %{
        title: "官方",
        raw: "offical",
        group: "资讯"
      },
      %{
        title: "业界新闻",
        raw: "news",
        group: "资讯"
      },
      %{
        title: "言论",
        raw: "views",
        group: "资讯"
      },
      %{
        title: "框架 / 库",
        raw: "release",
        group: "其他"
      },
      %{
        title: "有意思",
        raw: "others",
        group: "其他"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :radar, color: random_color()}, attr) end)
  end

  def get(_, :blog, :pl) do
    get(:ignore, :blog, :framework)
    # get(:ignore, :blog, :framework) |> Enum.reject(&(&1.raw in ["arch", "eco"]))
  end

  def get(_, :blog, :framework) do
    [
      %{
        title: "踩坑",
        raw: "trap",
        group: "工程"
      },
      %{
        title: "技巧",
        raw: "tips",
        group: "工程"
      },
      %{
        title: "重构",
        raw: "clean-code",
        group: "工程"
      },
      %{
        title: "教程",
        raw: "tuts",
        group: "其他"
      },
      %{
        title: "生态链",
        raw: "eco",
        group: "其他"
      },
      %{
        title: "杂谈",
        raw: "others",
        group: "其他"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :blog, color: random_color()}, attr) end)
  end

  def get(_, :tut, :pl) do
    get(:ignore, :tut, :framework)
  end

  def get(_, :tut, :framework) do
    [
      %{
        title: "速查表",
        raw: "cheatsheet"
      },
      %{
        title: "Tips",
        raw: "tips"
      },
      %{
        title: "工具链",
        raw: "tooling"
      },
      %{
        title: "工具链",
        raw: "tooling"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :tut, color: random_color()}, attr) end)
  end

  def get(_, :job, :pl) do
    get(:ignore, :job, :home) |> Enum.reject(&(&1.group in ["职位"]))
  end

  def get(_, :job, :framework) do
    get(:ignore, :job, :home) |> Enum.reject(&(&1.group in ["职位"]))
  end

  def get(_, :awesome, :pl), do: []
  def get(_, :awesome, :framework), do: []

  def get(_, :works, :pl), do: []
  def get(_, :works, :framework), do: []

  ## 语言与框架 end

  @doc "post thread of BLACK community"
  def get(%Community{raw: "blackhole"}, :post) do
    [
      %{
        title: "传单",
        raw: "flyer"
      },
      %{
        title: "标题党",
        raw: "clickbait"
      },
      %{
        title: "封闭平台",
        raw: "ugly"
      },
      %{
        raw: "pirated",
        title: "盗版 & 侵权"
      },
      %{
        raw: "copycat",
        title: "水贴"
      },
      %{
        raw: "no-good",
        title: "坏问题"
      },
      %{
        raw: "illegal",
        title: "无法无天"
      },
      %{
        raw: "others",
        title: "其他"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end

  @doc "post thread of MACKERS community"
  def get(%Community{raw: "makers"}, :post) do
    [
      %{
        title: "求教",
        raw: "ask",
        group: "讨论"
      },
      %{
        title: "推荐",
        raw: "REC",
        group: "讨论"
      },
      %{
        title: "生活",
        raw: "life",
        group: "讨论"
      },
      %{
        title: "脑洞",
        raw: "idea",
        group: "讨论"
      },
      %{
        title: "打招呼",
        raw: "say-hey",
        group: "讨论"
      },
      %{
        title: "小聚",
        raw: "meetup",
        group: "讨论"
      },
      %{
        title: "技术选型",
        raw: "arch",
        group: "产品打磨"
      },
      %{
        title: "即时分享",
        raw: "share",
        group: "产品打磨"
      },
      %{
        title: "App 上架",
        raw: "app",
        group: "合规问题"
      },
      %{
        title: "合规 & 资质",
        raw: "law",
        group: "合规问题"
      },
      %{
        title: "域名",
        raw: "domain",
        group: "其他"
      },
      %{
        title: "吐槽",
        raw: "WTF",
        group: "其他"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end

  @doc "post thread of ADWALL community"
  def get(%Community{raw: "adwall"}, :post) do
    [
      %{
        title: "产品推广",
        raw: "advertise"
      },
      %{
        title: "推荐 & 抽奖",
        raw: "discount"
      },
      %{
        title: "培训 & 课程",
        raw: "class"
      },
      %{
        title: "资料",
        raw: "collect"
      },
      %{
        title: "奇奇怪怪",
        raw: "others"
      }
    ]
    |> Enum.map(fn attr -> Map.merge(%{thread: :post, color: random_color()}, attr) end)
  end
end
