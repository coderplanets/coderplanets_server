From bitwalker/alpine-elixir-phoenix:latest

RUN mkdir /root/mastani_server
RUN mkdir /root/mastani_web

RUN npm install -g http-server
ADD mastani_server.tar.gz /root/mastani_server
ADD loader.sh /user/local/bin/loader.sh
RUN chmod +x /user/local/bin/loader.sh
CMD ["/user/local/bin/loader.sh"]