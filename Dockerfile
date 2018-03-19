From bitwalker/alpine-elixir-phoenix:latest

RUN mkdir hello_phoenix
ADD start.sh /user/local/bin/start.sh
RUN chmod +x /user/local/bin/start.sh
CMD ["/user/local/bin/start.sh"]
