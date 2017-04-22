FROM alpine:3.3
RUN apk --update upgrade && \
    apk add curl ca-certificates && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*
RUN apk add --no-cache wget jq
RUN wget --no-cache $(wget -qO- https://api.github.com/repos/reaandrew/fake-winter-fuel-benefit-service/releases/latest | jq -r ". | .assets[] | select(.name | contains(\"linux_amd64\")) | .browser_download_url")
RUN chmod +x /linux_amd64_fake-winter-fuel-benefit-service
CMD ["/linux_amd64_fake-winter-fuel-benefit-service"]
