FROM golang:alpine3.19 as builder
RUN ls ./
WORKDIR /opt/zipproperty
COPY . .
RUN go build 

FROM alpine:3.19
WORKDIR /opt/zipproperty
RUN mkdir /opt/zipproperty/bin
COPY --from=builder /opt/zipproperty /opt/zipproperty/bin