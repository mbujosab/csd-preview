;;; publish.el --- Build ciudadsantodomingo.org from index.org -*- lexical-binding: t; -*-
;;
;; Usage (from the site/ directory):
;;   emacs --batch --quick --load publish.el --funcall csd-publish
;; or, equivalently:
;;   make html
;;
;; Each top-level subtree of index.org whose :EXPORT_FILE_NAME: property is set
;; is exported to its own HTML file under public/. Static assets (css/, img/,
;; docs/) are copied separately by the Makefile.

(require 'org)
(require 'ox-html)
(require 'ol)

;; tel: links are rendered as plain styled text (NOT clickable). Keeping the
;; Org link syntax means we can revert later by just changing the :export.
(org-link-set-parameters
 "tel"
 :follow (lambda (path _) (browse-url (concat "tel:" path)))
 :export (lambda (path desc backend _info)
           (when (eq backend 'html)
             (format "<span class=\"phone\">%s</span>" (or desc path)))))

;; Register abs: for absolute-path resources (images and downloads).
;; Pages live at /, /asuntos-comunidad/, etc., so relative paths to /img and
;; /docs are awkward; abs: always produces a root-relative href.
;;   [[abs:/img/foo.jpg]]                  -> <img src="/img/foo.jpg" alt="" />
;;   [[abs:/img/foo.jpg][Plaza al sol]]    -> <img src="/img/foo.jpg" alt="Plaza al sol" />
;;   [[abs:/docs/foo.pdf][Descargar]]      -> <a class="pdf" href="/docs/foo.pdf">Descargar</a>
(defconst csd-image-extensions '("jpg" "jpeg" "png" "gif" "webp" "svg"))
(org-link-set-parameters
 "abs"
 :follow (lambda (path _) (browse-url (concat "file:" path)))
 :export (lambda (path desc backend _info)
           (when (eq backend 'html)
             (let* ((ext (downcase (or (file-name-extension path) "")))
                    (image-p (member ext csd-image-extensions))
                    (pdf-p   (string= ext "pdf")))
               (cond
                (image-p
                 ;; Plain image, NOT wrapped in <a>. The home-page gallery wraps
                 ;; its own thumbnails in lightbox anchors via inline HTML.
                 (format "<img src=\"%s\" alt=\"%s\" />" path (or desc "")))
                (pdf-p
                 (format "<a class=\"pdf\" href=\"%s\">%s</a>"
                         path (or desc path)))
                (t
                 (format "<a href=\"%s\">%s</a>" path (or desc path))))))))

(defvar csd-project-root
  (file-name-directory (or load-file-name buffer-file-name default-directory))
  "Absolute path of the site/ directory.")

(defvar csd-current-nav nil
  "Value of the NAV_KEY property of the subtree currently being exported.
Used by `csd-preamble' to highlight the active menu item.")

(defvar csd-base-url (or (getenv "CSD_BASE_URL") "")
  "URL prefix prepended to every root-absolute URL in the exported HTML.
Set via the CSD_BASE_URL environment variable; empty by default (the site
is served from the root of a domain).

Example: when serving from a GitHub Pages project repo at
\"https://USER.github.io/csd-preview/\", run

    make build CSD_BASE_URL=/csd-preview

…and every src=\"/...\" / href=\"/...\" becomes src=\"/csd-preview/...\".

Production (FTP to the real hosting that lives at the domain root) uses
an empty value, the default.")

(defconst csd-menu-items
  '(("inicio"        . ("Inicio"               . "/"))
    ("comunidad"     . ("Comunidad"            . "/asuntos-comunidad/"))
    ("municipales"   . ("Municipio"            . "/asuntos-municipales/"))
    ("oficina"       . ("Área Privada"         . "/oficina-virtual/")))
  "Main navigation: (NAV_KEY . (LABEL . URL)).")

(defun csd--menu-html ()
  "Render the main nav, marking `csd-current-nav' as active."
  (mapconcat
   (lambda (item)
     (let* ((key   (car item))
            (label (cadr item))
            (url   (cddr item))
            (active (string= key (or csd-current-nav ""))))
       (format "<a href=\"%s\"%s>%s</a>"
               url
               (if active " class=\"active\" aria-current=\"page\"" "")
               label)))
   csd-menu-items
   "\n      "))

(defun csd-preamble (_info)
  "Header + main navigation, identical on every page."
  (format "<header class=\"site-header\">
  <div class=\"site-header-inner\">
    <a class=\"brand\" href=\"/\">
      <img src=\"/img/logoTransparente.svg\" alt=\"Ciudad Santo Domingo\" />
      <span>Ciudad Santo Domingo</span>
    </a>
    <nav class=\"site-nav\" aria-label=\"Navegación principal\">
      %s
    </nav>
  </div>
</header>"
          (csd--menu-html)))

(defun csd-postamble (_info)
  "Footer with contact info and legal links."
  (format "<footer class=\"site-footer\">
  <div class=\"contact\">
    <strong>Comunidad de Propietarios Ciudad Santo Domingo</strong><br />
    Avda. del Guadalix, 37 · 28120 Algete (Madrid)<br />
    Tel.: <span class=\"phone\">916 221 511</span> ·
    Email: <a href=\"mailto:csd@csdomingo.com\">csd@csdomingo.com</a><br />
    Seguridad 24 h: <span class=\"phone\">916 221 507</span>
  </div>
  <nav class=\"footer-nav\" aria-label=\"Enlaces legales\">
    <a href=\"/aviso-legal/\">Aviso legal</a> ·
    <a href=\"/politica-de-privacidad/\">Política de privacidad</a>
  </nav>
  <div class=\"copy\">&copy; %s Comunidad de Propietarios Ciudad Santo Domingo</div>
</footer>"
          (format-time-string "%Y")))

;; Global export defaults: clean HTML5, no Org boilerplate.
(setq org-html-doctype                "html5"
      org-html-html5-fancy            t
      org-html-validation-link        nil
      org-html-head-include-default-style nil
      org-html-head-include-scripts   nil
      org-html-preamble               #'csd-preamble
      org-html-postamble              #'csd-postamble
      org-html-head
      "<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\" />
<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin />
<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;600;700&amp;family=Philosopher:wght@400;700&amp;display=swap\" />
<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/style.css\" />
<link rel=\"icon\" type=\"image/jpeg\" href=\"/img/favicon.jpg\" />"
      org-export-with-section-numbers nil
      org-export-with-toc             nil
      org-export-with-author          nil
      org-export-with-creator         nil
      org-export-with-date            nil
      org-export-with-title           t
      org-export-with-sub-superscripts nil
      make-backup-files               nil)

(defun csd-rewrite-paths-filter (output backend _info)
  "Prepend `csd-base-url' to every root-absolute URL in OUTPUT.
Only runs for HTML export and when `csd-base-url' is non-empty.
Does NOT touch protocol-relative URLs (\"//cdn…\") or other prefixes.

Implemented as a single pass: the regex matches \"/X\" where X is any
character that is NOT another slash. That covers both \"/\" (home link,
X is the closing quote) and \"/foo\" (any path, X is a letter). It
avoids matching protocol-relative \"//host/…\". Running in one pass is
critical: a second pass would also match the freshly inserted prefix
and double it (e.g. /csd-preview/csd-preview/)."
  (if (and (eq backend 'html)
           (stringp csd-base-url)
           (not (string-empty-p csd-base-url)))
      (replace-regexp-in-string
       "\\(\\(?:src\\|href\\)=\"\\)/\\([^/]\\)"
       (concat "\\1" csd-base-url "/\\2")
       output)
    output))

(add-to-list 'org-export-filter-final-output-functions
             #'csd-rewrite-paths-filter)

(defun csd-publish ()
  "Export each top-level subtree of index.org that has :EXPORT_FILE_NAME:."
  (interactive)
  (let ((default-directory csd-project-root))
    (with-current-buffer (find-file-noselect
                          (expand-file-name "index.org" csd-project-root))
      (org-mode)
      (org-map-entries
       (lambda ()
         (let ((file (org-entry-get nil "EXPORT_FILE_NAME"))
               (nav  (org-entry-get nil "NAV_KEY")))
           (when file
             (setq csd-current-nav (or nav ""))
             (message ">> Exportando %s.html (NAV_KEY=%s)" file nav)
             (let* ((default-directory csd-project-root)
                    (dir (file-name-directory
                          (expand-file-name file csd-project-root))))
               (when dir (make-directory dir t))
               (org-html-export-to-html nil t)))))
       "LEVEL=1"))))

(provide 'publish)
;;; publish.el ends here
