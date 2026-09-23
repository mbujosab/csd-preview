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

.PHONY: build html assets clean serve pdf pdf-docs pdf-clean

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

# ---------------------------------------------------------------- PDF
# Dosieres PDF generados desde documentos.org con LuaLaTeX (ver publish-pdf.el
# y pdf/csd-dossier.sty). Se compilan en local (el CI no tiene TeX):
#   make pdf                        # todos -> pdf/build/
#   make pdf DOC=gestion-del-agua   # solo uno
#   make pdf-docs                   # compila y copia a docs/ (lo que enlaza la web)
PDF_BUILD := pdf/build
DOC ?=
PDF_LOGOS := $(PDF_BUILD)/logo-csd.pdf $(PDF_BUILD)/logo-csd-blanco.pdf

$(PDF_BUILD)/logo-csd.pdf: img/logoTransparente.svg
	mkdir -p $(PDF_BUILD)
	inkscape $< --export-type=pdf --export-filename=$@

$(PDF_BUILD)/logo-csd-blanco.pdf: img/logos/logoFondoBlanco.svg
	mkdir -p $(PDF_BUILD)
	inkscape $< --export-type=pdf --export-filename=$@

pdf: $(PDF_LOGOS)
	CSD_PDF_DOC=$(DOC) $(EMACS) --batch --quick \
	  --load publish-pdf.el \
	  --funcall csd-publish-pdf

pdf-docs: pdf
	@for f in $$(sed -n 's/^:EXPORT_FILE_NAME: *//p' documentos.org); do \
	  if [ -z "$(DOC)" ] || [ "$(DOC)" = "$$f" ]; then \
	    cp -v $(PDF_BUILD)/$$f.pdf docs/$$f.pdf; fi; done

pdf-clean:
	rm -rf $(PDF_BUILD)
