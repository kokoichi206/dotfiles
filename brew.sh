#!/bin/bash

# Install command-line tools using Homebrew from Brewfile
#
# To update Brewfile with currently installed packages:
#   brew bundle dump --force

brew update

# Install packages from Brewfile
brew bundle --file=Brewfile
