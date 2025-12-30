.PHONY: all build run clean help install update

all: build

build:
	@echo "Building mac-eq..."
	swift build

run: build
	@echo "Running mac-eq..."
	swift run

clean:
	@echo "Cleaning build artifacts..."
	swift package clean

xcode:
	@echo "Generating Xcode project..."
	swift package generate-xcodeproj

install: build
	@echo "Installing to /usr/local/bin..."
	cp .build/debug/mac-eq /usr/local/bin/mac-eq

update:
	@echo "Updating dependencies..."
	swift package update

release:
	@echo "Building release..."
	swift build -c release

help:
	@echo "mac-eq Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build     - Build the project"
	@echo "  make run       - Build and run the app"
	@echo "  make clean     - Clean build artifacts"
	@echo "  make xcode     - Generate Xcode project"
	@echo "  make install   - Install to /usr/local/bin"
	@echo "  make update    - Update dependencies"
	@echo "  make release   - Build release version"
	@echo "  make help      - Show this help message"