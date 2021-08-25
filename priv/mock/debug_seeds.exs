alias GroupherServer.CMS

CMS.clean_up_community(:home)
{:ok, community} = CMS.seed_community(:home)
CMS.seed_articles(community, :post, 5)
