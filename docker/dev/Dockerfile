From bitwalker/alpine-elixir-phoenix:latest

RUN mkdir /root/api_server
RUN mkdir /root/mastani_api_monitor

# change timezone to +8
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone

ADD api_server.tar.gz /root/api_server
RUN mix hex.config mirror_url https://hexpm.upyun.com
RUN cd /root/api_server && mix deps.get && MIX_ENV=dev mix compile

# ADD monitor/index.js /root/mastani_api_monitor
# ADD monitor/package.json /root/mastani_api_monitor
# ADD monitor/package-lock.json /root/mastani_api_monitor
# RUN cd /root/mastani_api_monitor/ && npm install --registry=https://registry.npm.taobao.org

ADD loader.sh /user/local/bin/loader.sh
RUN chmod +x /user/local/bin/loader.sh
CMD ["/user/local/bin/loader.sh"]