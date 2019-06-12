From bitwalker/alpine-elixir-phoenix:1.6.6

RUN mkdir /root/api_server
# RUN mkdir /root/groupher_api_monitor

# change timezone to +8

# 备份原始文件
RUN cp /etc/apk/repositories /etc/apk/repositories.bak
# 修改为国内镜像源
RUN echo "http://mirrors.aliyun.com/alpine/v3.4/main/" > /etc/apk/repositories
RUN apk add tzdata --force-broken-world
# RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

ADD api_server.tar.gz /root/api_server
# RUN mix hex.config mirror_url https://hexpm.upyun.com
RUN mix hex.config mirror_url https://cdn.jsdelivr.net/hex
RUN cd /root/api_server && mix deps.get --only dev && MIX_ENV=dev mix compile

ADD loader.sh /usr/local/bin/loader.sh
RUN chmod +x /usr/local/bin/loader.sh
CMD ["/usr/local/bin/loader.sh"]