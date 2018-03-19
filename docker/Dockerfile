From bitwalker/alpine-elixir-phoenix:latest

RUN mkdir /root/mastani_server
ADD mastani_server.tar.gz /root
ADD loader.sh /user/local/bin/loader.sh
RUN chmod +x /user/local/bin/loader.sh
CMD ["/user/local/bin/loader.sh"]