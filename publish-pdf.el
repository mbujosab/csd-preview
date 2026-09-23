;;; publish-pdf.el --- Build the PDF dossiers from documentos.org -*- lexical-binding: t; -*-
;;
;; Usage (from the repository root):
;;   emacs --batch --quick --load publish-pdf.el --funcall csd-publish-pdf
;; or, equivalently:
;;   make pdf                        # every dossier
;;   make pdf DOC=gestion-del-agua   # only one
;;
;; Each top-level subtree of documentos.org whose :EXPORT_FILE_NAME: property
;; is set is exported to pdf/build/NAME.tex and compiled with LuaLaTeX
;; (latexmk) into pdf/build/NAME.pdf. `make pdf-docs' then copies the PDFs
;; into docs/, which is what the web links to.
;;
;; The look (cover, header, colours, boxes) lives in pdf/csd-dossier.sty.
;; The logos are converted from the SVGs in img/ by the Makefile.

(require 'org)
(require 'ox-latex)

(defvar csd-pdf-root
  (file-name-directory (or load-file-name buffer-file-name default-directory))
  "Absolute path of the repository root.")

(defvar csd-pdf-build-dir (expand-file-name "pdf/build/" csd-pdf-root)
  "Where the intermediate .tex files and the resulting PDFs are written.")

(defvar csd-pdf-only (let ((d (getenv "CSD_PDF_DOC")))
                       (and d (not (string-empty-p d)) d))
  "If non-nil, build only the dossier whose EXPORT_FILE_NAME is this.")

(defun csd-pdf--classes (etiqueta titulo)
  "LaTeX classes for a document whose header label is ETIQUETA.
TITULO is the document title; a trailing \"Ciudad Santo Domingo\" is
dropped from the cover, which always prints that name on its own line.
Two classes: csd-dossier (default) and csd-compendio, where each level-1
heading is a chapter (\\csdcapitulo, with a cover page added by
`csd-pdf--portadilla')."""
  (let ((header (concat "\\documentclass[11pt,a4paper]{article}\n"
                        "[NO-DEFAULT-PACKAGES]\n[NO-PACKAGES]\n"
                        "\\usepackage{csd-dossier}\n"
                        "%s"
                        (format "\\csdetiqueta{%s}\n" (or etiqueta ""))
                        (format "\\csdtituloportada{%s}\n"
                                (string-trim
                                 (replace-regexp-in-string
                                  "Ciudad Santo Domingo\\'" "" titulo)))
                        "[EXTRA]"))
        (secciones '(("\\section{%s}" . "\\section*{%s}")
                     ("\\subsection{%s}" . "\\subsection*{%s}")
                     ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                     ("\\paragraph{%s}" . "\\paragraph*{%s}"))))
    (list (append (list "csd-dossier" (format header "")) secciones)
          (append (list "csd-compendio" (format header "\\csdcompendiotrue\n")
                        '("\\csdcapitulo{%s}" . "\\csdcapitulo{%s}"))
                  secciones))))

(defun csd-pdf--portadilla (orig headline contents info)
  "Put a cover page before each chapter of the csd-compendio class.
Skipped when the heading has the property :PORTADILLA: no."
  (let ((out (funcall orig headline contents info)))
    (if (and (equal (plist-get info :latex-class) "csd-compendio")
             (= (org-export-get-relative-level headline info) 1)
             (not (equal (org-element-property :PORTADILLA headline) "no")))
        (concat (format "\\csdportadilla{%s}\n"
                        (org-export-data (org-element-property :title headline)
                                         info))
                out)
      out)))
(advice-add 'org-latex-headline :around #'csd-pdf--portadilla)

(setq org-latex-compiler              "lualatex"
      org-latex-tables-booktabs       t
      org-latex-default-figure-position "H"
      org-latex-image-default-width   ".8\\linewidth"
      org-latex-hyperref-template     nil
      org-export-with-section-numbers nil
      org-export-with-toc             nil
      org-export-with-author          nil
      org-export-with-creator         nil
      org-export-with-date            t
      org-export-with-title           t
      org-export-with-sub-superscripts '{}
      make-backup-files               nil)

(defun csd-pdf--latexmk (tex)
  "Compile TEX with latexmk/LuaLaTeX from the repository root.
Running from the root lets image paths in documentos.org
\(e.g. pdf/img/foo.jpg) resolve both in Emacs and in LaTeX."
  (let* ((default-directory csd-pdf-root)
         (process-environment
          (cons (concat "TEXINPUTS=" (expand-file-name "pdf/" csd-pdf-root)
                        ":" csd-pdf-build-dir ":")
                process-environment))
         (status (call-process "latexmk" nil "*latexmk*" nil
                               "-lualatex" "-interaction=nonstopmode"
                               "-halt-on-error" "-quiet"
                               (concat "-outdir=" csd-pdf-build-dir)
                               tex)))
    (unless (eq status 0)
      (with-current-buffer "*latexmk*" (message "%s" (buffer-string)))
      (message "!! LaTeX falló compilando %s (ver %s)"
               (file-name-nondirectory tex)
               (file-relative-name (concat (file-name-sans-extension tex) ".log")
                                   csd-pdf-root))
      (kill-emacs 1))))

(defun csd-publish-pdf ()
  "Export and compile each top-level subtree of documentos.org."
  (interactive)
  (make-directory csd-pdf-build-dir t)
  (with-current-buffer (find-file-noselect
                        (expand-file-name "documentos.org" csd-pdf-root))
    (org-mode)
    (org-map-entries
     (lambda ()
       (let ((name (org-entry-get nil "EXPORT_FILE_NAME"))
             (etiqueta (org-entry-get nil "ETIQUETA"))
             (titulo (or (org-entry-get nil "EXPORT_TITLE")
                         (org-get-heading t t t t))))
         (when (and name (or (null csd-pdf-only) (string= name csd-pdf-only)))
           (let ((tex (expand-file-name (concat name ".tex") csd-pdf-build-dir))
                 (org-latex-classes (csd-pdf--classes etiqueta titulo))
                 (org-latex-default-class "csd-dossier"))
             (message ">> %s.pdf" name)
             (org-export-to-file 'latex tex nil t nil nil '(:date ""))  ; sin fecha si no hay EXPORT_DATE
             (csd-pdf--latexmk tex)))))
     "LEVEL=1")))

(provide 'publish-pdf)
;;; publish-pdf.el ends here
