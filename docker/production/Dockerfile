From bitwalker/alpine-elixir-phoenix:latest

RUN mkdir /root/mastani_server
RUN mkdir /root/mastani_web
RUN mkdir /root/mastani_api_monitor

RUN npm install -g http-server --registry=https://registry.npm.taobao.org
ADD mastani_server.tar.gz /root/mastani_server
ADD monitor/index.js /root/mastani_api_monitor
ADD monitor/package.json /root/mastani_api_monitor
ADD monitor/package-lock.json /root/mastani_api_monitor
RUN cd /root/mastani_api_monitor/ && npm install --registry=https://registry.npm.taobao.org
ADD index.html /root/mastani_web
ADD loader.sh /user/local/bin/loader.sh
RUN chmod +x /user/local/bin/loader.sh
CMD ["/user/local/bin/loader.sh"]