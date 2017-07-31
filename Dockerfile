# Build envrionment
FROM golang:1.7.3 as builder
WORKDIR /usr/src
RUN go get -d -v \
    golang.org/x/net/html \
    github.com/gorilla/mux \
    gopkg.in/mgo.v2 \
    gopkg.in/mgo.v2/bson
COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Run environment
FROM alpine:latest
RUN apk --no-cache add \
    ca-certificates
WORKDIR /usr/src/app
COPY --from=builder /usr/src/main .
EXPOSE 8080
CMD ["./main"]
