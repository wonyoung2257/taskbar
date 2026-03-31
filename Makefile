VERSION ?= 0.1.0

APP_NAME := TBar.app
APP_DIR := .build/$(APP_NAME)
APP_CONTENTS := $(APP_DIR)/Contents
APP_MACOS := $(APP_CONTENTS)/MacOS
RELEASE_DIR := .build/release
UNIVERSAL_DIR := .build/apple/Products/Release
ZIP_STAGING_DIR := .build/release-package
ZIP_NAME := tbar-$(VERSION)-universal.zip
ZIP_PATH := .build/$(ZIP_NAME)

.PHONY: build build-universal app app-universal install uninstall clean test release-zip

build:
	swift build -c release --disable-sandbox

build-universal:
	swift build -c release --disable-sandbox --arch arm64 --arch x86_64

app: build
	mkdir -p $(APP_MACOS)
	cp $(RELEASE_DIR)/TBarApp $(APP_MACOS)/TBar
	cp Resources/Info.plist $(APP_CONTENTS)/

app-universal: build-universal
	mkdir -p $(APP_MACOS)
	cp $(UNIVERSAL_DIR)/TBarApp $(APP_MACOS)/TBar
	cp Resources/Info.plist $(APP_CONTENTS)/

install: app
	mkdir -p /usr/local/bin
	install -m 755 $(RELEASE_DIR)/tbar /usr/local/bin/tbar
	rm -rf /Applications/TBar.app
	cp -R $(APP_DIR) /Applications/TBar.app

uninstall:
	rm -f /usr/local/bin/tbar
	rm -rf /Applications/TBar.app

clean:
	swift package clean
	rm -rf $(APP_DIR)

test:
	swift test --disable-sandbox

release-zip: app-universal
	rm -rf $(ZIP_STAGING_DIR) $(ZIP_PATH)
	mkdir -p $(ZIP_STAGING_DIR)
	cp -R $(APP_DIR) $(ZIP_STAGING_DIR)/TBar.app
	cp $(UNIVERSAL_DIR)/tbar $(ZIP_STAGING_DIR)/tbar
	cd $(ZIP_STAGING_DIR) && zip -qry ../$(ZIP_NAME) TBar.app tbar
