alias GroupherServer.CMS
# alias Helper.ORM

# ORM.delete_all(CMS.Model.Thread, :if_exist)

CMS.clean_up_community(:home)
{:ok, community} = CMS.seed_community(:home)

# hello = ORM.find(CMS.Model.Community, community.id)
# IO.inspect(hello, label: "hello -> ")

CMS.seed_articles(community, :post, 5)
CMS.seed_articles(community, :job, 5)
CMS.seed_articles(community, :blog, 5)
CMS.seed_articles(community, :radar, 5)
CMS.seed_articles(community, :meetup, 5)
CMS.seed_articles(community, :works, 10)
