USERNAME="reaandrew"
PROJECT="fake-winter-fuel-benefit-service"
ITHUB_TOKEN=$$GITHUB_TOKEN
VERSION=`cat VERSION`
BUILD_TIME=`date +%FT%T%z`
COMMIT_HASH=`git rev-parse HEAD`
DIST_NAME_CONVENTION="dist/{{.OS}}_{{.Arch}}_{{.Dir}}"

DEPLOY_KEY_NAME="fwfbs"
DEPOY_PUBLIC_KEY_PATH="~/.ssh/$(DEPLOY_KEY_NAME).pub"
AWS_REGION="eu-west-1"
#Ubuntu 14.04 LTS,amd64,hvm:ebs
AWS_AMI="ami-a1447cc7"

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
	CGO_ENABLED=0 go build ${LDFLAGS} -o ${BINARY} 

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
	CGO_ENABLED=0 gox -osarch="linux/amd64" -output ${DIST_NAME_CONVENTION} ${LDFLAGS}

.PHONY: shasums
shasums:
	shasum -a 256 dist/* > "dist/${PROJECT}-${VERSION}-shasums.txt"

.PHONY: package
package: cross-platform-compile shasums

.PHONY: upload-release
upload-release:
	ghr -t ${GITHUB_TOKEN} -u ${USERNAME} -r ${PROJECT} --delete ${VERSION} dist/

.PHONY: aws-deploy
aws-deploy:
	(cd deploy && terraform apply -var "key_name=$(DEPLOY_KEY_NAME)" \
								  -var "public_key_path=$(DEPOY_PUBLIC_KEY_PATH)" \
								  -var "aws_region=$(AWS_REGION)" \
								  -var "aws_ami=$(AWS_AMI)")

.PHONY: aws-destroy
aws-destroy:
	(cd deploy && terraform destroy -var "key_name=$(DEPLOY_KEY_NAME)" \
									-var "public_key_path=$(DEPOY_PUBLIC_KEY_PATH)" \
									-var "aws_region=$(AWS_REGION)" \
									-var "aws_ami=$(AWS_AMI)")
