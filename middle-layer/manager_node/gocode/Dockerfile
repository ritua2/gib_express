FROM golang:1.10.4-alpine


COPY traffic.go /conductor/traffic.go
COPY startup.sh /scripts/startup.sh

# For cases where login in is needed
RUN apk add --no-cache bash git && go get github.com/gorilla/mux && go get github.com/go-redis/redis


WORKDIR /conductor
