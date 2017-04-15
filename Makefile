USERNAME="reaandrew"
PROJECT="fake-winter-fuel-benefit-service"
ITHUB_TOKEN=$$GITHUB_TOKEN
VERSION=`cat VERSION`
BUILD_TIME=`date +%FT%T%z`
COMMIT_HASH=`git rev-parse HEAD`
DIST_NAME_CONVENTION="dist/{{.OS}}_{{.Arch}}_{{.Dir}}"

SOURCEDIR=.
SOURCES := $(shell find $(SOURCEDIR) -name '*.go')
SOURCES += VERSION
# This is how we want to name the binary output
BINARY=${PROJECT}

# These are the values we want to pass for Version and BuildTime

# Setup the -ldflags option for go build here, interpolate the variable values
LDFLAGS=-ldflags "-X main.CommitHash=${COMMIT_HASH} -X main.Version=${VERSION} -X main.BuildTime=${BUILD_TIME}"

.DEFAULT_GOAL: build

.PHONY: build
build: deps $(SOURCES) lint test
	go build ${LDFLAGS} -o ${BINARY} 

.PHONY: deps 
deps:
	go get -u github.com/alecthomas/gometalinter
	gometalinter --install
	go get -t ./...

.PHONY: package-deps
package-deps:
	go get -u github.com/mitchellh/gox
	go get -u github.com/tcnksm/ghr

.PHONY: install
install:
	go install ${LDFLAGS} ./...

.PHONY: clean
clean:
	if [ -f ${BINARY} ] ; then rm ${BINARY} ; fi

.PHONY: lint
lint:
	gometalinter --concurrency=4

.PHONY: test
test:
	go test -cover -coverprofile=coverage.out

.PHONY: cross-platform-compile
cross-platform-compile: package-deps
	gox -osarch="linux/amd64" -output ${DIST_NAME_CONVENTION} ${LDFLAGS}

.PHONY: shasums
shasums:
	shasum -a 256 dist/* > "dist/${PROJECT}-${VERSION}-shasums.txt"

.PHONY: package
package: cross-platform-compile shasums

.PHONY: upload-release
upload-release:
	ghr -t ${GITHUB_TOKEN} -u ${USERNAME} -r ${PROJECT} --delete ${VERSION} dist/

