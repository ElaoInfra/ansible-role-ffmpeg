.SILENT:
.PHONY: help

## Colors
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[32m
COLOR_COMMENT = \033[33m

## Package
PACKAGE_NAME        = ffmpeg-static
PACKAGE_DESCRIPTION = A complete, cross-platform solution to record, convert and stream audio and video.
PACKAGE_VERSION     = 2.8
PACKAGE_RELEASE     = elao1
PACKAGE_GROUP       = video
PACKAGE_PROVIDES    = ffmpeg
PACKAGE_MAINTAINER  = infra@elao.com
PACKAGE_LICENSE     = LGPL

## Package - Source
PACKAGE_SOURCE = http://johnvansickle.com/ffmpeg/releases

## Help
help:
	printf "${COLOR_COMMENT}Usage:${COLOR_RESET}\n"
	printf " make [target]\n\n"
	printf "${COLOR_COMMENT}Available targets:${COLOR_RESET}\n"
	awk '/^[a-zA-Z\-\_0-9\.@]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf " ${COLOR_INFO}%-16s${COLOR_RESET} %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

## Build
build: build-packages

build-packages:
	docker run \
	    --rm \
	    --volume `pwd`:/srv \
	    --workdir /srv \
	    --tty \
	    debian:wheezy \
	    sh -c '\
	        apt-get update && \
	        apt-get install -y make && \
	        make build-package@debian-wheezy \
	    '

build-package@debian-wheezy:
	apt-get install -y wget checkinstall
	# Get origin package
	wget ${PACKAGE_SOURCE}/ffmpeg-${PACKAGE_VERSION}-64bit-static.tar.xz -O ~/origin.tar.xz
	# Extract origin package
	mkdir -p ~/origin
	tar xfv ~/origin.tar.xz -C ~/origin --strip-components=1
	# Prepare package
	mkdir -p ~/package/usr/bin
	mv ~/origin/ffmpeg ~/origin/ffprobe ~/package/usr/bin
	# Package files
	echo "./usr/bin/ffmpeg" > ~/package/include-files
	echo "./usr/bin/ffprobe" >> ~/package/include-files
	# Package description
	echo ${PACKAGE_DESCRIPTION} > ~/package/description-pak
	# Checkinstall
	cd ~/package && checkinstall \
	    -y \
	    --install=no \
	    --nodoc \
	    --include=include-files \
	    --pkgname=${PACKAGE_NAME} \
	    --pkgversion=${PACKAGE_VERSION} \
	    --pkgrelease=${PACKAGE_RELEASE} \
	    --pkggroup=${PACKAGE_GROUP} \
	    --provides=${PACKAGE_PROVIDES} \
	    --maintainer=${PACKAGE_MAINTAINER} \
	    --pkglicense=${PACKAGE_LICENSE} \
	    --pkgsource=${PACKAGE_SOURCE} \
	    true
	# Move package files
	rm -f /srv/files/*.deb
	mv ~/package/*.deb /srv/files
