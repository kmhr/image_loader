#!/usr/local/bin/zsh

export LANG=C

while true; do
	date
	bundle exec ./tumblr_image_loader.rb 2> /dev/null
	sleep 3600
done
