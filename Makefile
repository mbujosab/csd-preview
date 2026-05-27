EMACS ?= emacs

# URL prefix for the generated HTML. Empty = served from the root of a domain
# (production hosting). Set e.g. to /csd-preview for a GitHub Pages project
# repo at https://USER.github.io/csd-preview/.
#
# Examples:
#   make build                       # production, URLs as /css/style.css
#   make build CSD_BASE_URL=/csd-preview
CSD_BASE_URL ?=
export CSD_BASE_URL

PUBLIC := public

.PHONY: build html assets clean serve

build: html assets

html:
	$(EMACS) --batch --quick \
	  --load publish.el \
	  --funcall csd-publish

assets:
	mkdir -p $(PUBLIC)/css $(PUBLIC)/img $(PUBLIC)/docs
	cp -r css/. $(PUBLIC)/css/
	cp -r img/. $(PUBLIC)/img/
	cp -r docs/. $(PUBLIC)/docs/

clean:
	rm -rf $(PUBLIC)

serve: build
	cd $(PUBLIC) && python3 -m http.server 8080
