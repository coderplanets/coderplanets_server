alias GroupherServer.CMS
alias Helper.ORM

# ORM.delete_all(CMS.Model.Thread, :if_exist)

CMS.clean_up_community(:home)
{:ok, community} = CMS.seed_community(:home)

hello = ORM.find(CMS.Model.Community, community.id)

# IO.inspect(hello, label: "hello -> ")

CMS.seed_articles(community, :post, 5)
