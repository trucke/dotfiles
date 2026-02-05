#!/usr/bin/env bash

if ! command -v mise &>/dev/null; then
	echo "mise is not installed. Please run 'omarchy-pkg-add mise' first."
	exit 1
fi

mise install -y

echo "Dev tools successfully installed."
