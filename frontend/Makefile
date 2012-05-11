CURL=curl -s -o -
JQUERY_VERSION=1.7.2

ALL:

js/deps:
	mkdir -p $@

js/deps/d3.v2.min.js: js/deps
	$(CURL) http://mbostock.github.com/d3/d3.v2.min.js > $@

js/deps/underscore-min.js: js/deps
	$(CURL) http://documentcloud.github.com/underscore/underscore-min.js > $@

js/deps/jquery.min.js: js/deps
	$(CURL) http://code.jquery.com/jquery-$(JQUERY_VERSION).min.js > $@

js-deps: js/deps/d3.v2.min.js js/deps/jquery.min.js js/deps/underscore-min.js

PHONY:
