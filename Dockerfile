FROM elixir:1.7 AS build

COPY apps apps
COPY Makefile Makefile
COPY mix.exs mix.exs
COPY mix.lock mix.lock
COPY config config

RUN rm -Rf _build && \
  mix local.hex --force && \
  mix local.rebar --force && \
  make build cli

RUN mkdir -p /export && cp ogawa_cli /export

FROM erlang:21

ENV LANG=C.UTF-8

RUN mkdir -p /opt/app
COPY --from=build /export/ /opt/app

CMD ["/opt/app/ogawa_cli", "-h"]
