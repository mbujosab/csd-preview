# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A static replacement for the WordPress site of the Comunidad de Propietarios of
**Ciudad Santo Domingo** (https://ciudadsantodomingo.org/, Algete, Madrid). The
goal is to migrate from WordPress/Divi to a single Org-mode source file that
exports to HTML via `org-publish`. Content is in Spanish.

Currently hosted as a **preview** on GitHub Pages at
`https://mbujosab.github.io/csd-preview/`; will eventually deploy via FTP to
the production hosting that serves `ciudadsantodomingo.org`.

The repository root IS the `site/` project (no parent wrapper). A read-only
`wget` mirror of the live WordPress site lives at
`../ciudadsantodomingo.org/` (outside this repo) and is used by
`import-assets.sh` to re-extract images/PDFs into `img/` and `docs/`.

## Commands

| Command                                | What it does                                                            |
|----------------------------------------|-------------------------------------------------------------------------|
| `make`                                 | Build everything → `public/`. Equivalent to `make build`.               |
| `make html`                            | Only re-exports `index.org` (no asset copy).                            |
| `make assets`                          | Only re-copies `css/`, `img/`, `docs/` into `public/`.                  |
| `make build CSD_BASE_URL=/csd-preview` | Build with a URL prefix (GitHub Pages of a project repo).               |
| `make serve`                           | Builds and serves on http://localhost:8080.                             |
| `make clean`                           | Wipes `public/`.                                                        |
| `make pdf`                             | Builds the PDF dossiers from `documentos.org` → `pdf/build/*.pdf` (needs LuaLaTeX and latexmk). |
| `make logos`                           | Regenerates `pdf/logo-csd*.pdf` from the SVGs in `img/` (needs Inkscape). The PDFs are committed. |
| `make pdf DOC=gestion-del-agua`        | Builds only that dossier.                                               |
| `make pdf-docs`                        | `make pdf` + copies the results into `docs/` (what the web links to).   |
| `./import-assets.sh`                   | (Re-)copies images and PDFs from `../ciudadsantodomingo.org/wp-content/uploads/` into `img/` and `docs/`. Idempotent. |

## CSD_BASE_URL

URL prefix prepended to every root-absolute URL (`/css/...`, `/img/...`,
`/asuntos-comunidad/`, …) by the post-export filter
`csd-rewrite-paths-filter` in `publish.el`. Reads the
`CSD_BASE_URL` env var at build time.

- **Empty** (default): production, the site is served from the root of a
  domain. URLs stay as `/css/...`.
- **`/csd-preview`**: GitHub Pages of the project repo, served at
  `https://mbujosab.github.io/csd-preview/`. URLs become
  `/csd-preview/css/...`.

The filter does NOT rewrite protocol-relative (`//cdn…`), absolute
(`https://…`), fragment-only (`#lb-1`) or other-scheme (`mailto:`, `tel:`)
URLs.

Underlying build command: `emacs --batch --quick --load publish.el --funcall csd-publish`.

## Architecture

### Single .org file, many HTML files

The entire textual content of the site lives in **`site/index.org`**. Each
top-level subtree (`*`) that has an `:EXPORT_FILE_NAME:` property is exported
to its own HTML file. So:

```
* Asuntos Comunidad
:PROPERTIES:
:EXPORT_FILE_NAME: public/asuntos-comunidad/index
:NAV_KEY: comunidad
:END:
```

…produces `site/public/asuntos-comunidad/index.html`. To add a new page:
create a new top-level subtree with these two properties. To rename a page:
change `EXPORT_FILE_NAME` and update the menu in `publish.el` and any
internal links.

`NAV_KEY` is used by `csd-preamble` in `publish.el` to mark the active menu
item. Valid keys are listed in `csd-menu-items`.

### publish.el

Single source of truth for export configuration. Defines:

- The main navigation menu (`csd-menu-items`) — edit here to add/remove
  top-level pages.
- `csd-preamble` (site header + nav) and `csd-postamble` (footer with
  contact info and legal links). Both are injected on every page.
- Two custom Org link types:
  - `[[tel:+34...][...]]` → `<a href="tel:...">`.
  - `[[abs:/img/foo.jpg][alt text]]` → `<img src="/img/foo.jpg" alt="alt text">`.
  - `[[abs:/docs/foo.pdf][Descargar]]` → `<a class="pdf" href="/docs/foo.pdf">Descargar</a>`.

  Use **absolute paths** (`/img/...`, `/docs/...`) because pages are served
  at different depths (`/`, `/asuntos-comunidad/`, …).

- `csd-publish` — the entry point: walks every level-1 subtree of
  `index.org`, creates parent directories as needed, and calls
  `org-html-export-to-html nil t` (subtree-only export) for each.

### CSS

`css/style.css` is the only stylesheet. Loaded from `/css/style.css` via
`org-html-head` in `publish.el`. The default Org HTML styles are disabled
(`org-html-head-include-default-style nil`).

The container is centered with `max-width: var(--max-width)` (currently
880 px). Tweak `:root` variables to change colors, max width, fonts.

### Static assets

Resolved by name only. To use an image: place it in `img/`, reference it as
`[[abs:/img/NAME.ext]]`. The Makefile copies `img/`, `docs/`, and `css/`
into `public/` on each build. Image and PDF naming convention is kebab-case
ASCII (no spaces, no accents, no size suffixes like `-1024x768`).

### PDF dossiers (documentos.org)

The downloadable PDFs the Comunidad writes itself are generated from a
second single source, **`documentos.org`**, one top-level subtree per PDF
(`:EXPORT_FILE_NAME:` = name in `docs/` without `.pdf`, `:EXPORT_DATE:`,
`:ETIQUETA:` = label in the page header). `publish-pdf.el` exports each
subtree to `pdf/build/NAME.tex` and compiles it with latexmk/LuaLaTeX,
running from the repo root so image links like `[[file:pdf/img/foo.jpg]]`
work both in Emacs and in LaTeX. The look (cover, header, fonts, colours,
`recuadro`/`destacado`/`aviso`/`fotos` special blocks) lives in
`pdf/csd-dossier.sty`. The logos are committed as `pdf/logo-csd*.pdf`
(`make logos` regenerates them with Inkscape). The six generated PDFs are
NOT committed: both workflows install a minimal TeX Live
(`teatimeguest/setup-texlive-action`, package list in the workflow) and run
`make pdf-docs` before `make build`, so every push rebuilds them. External
documents (municipal ordinances, bandos, vendor manuals) stay as plain
files in `docs/`.

## What's intentionally NOT in the site

- Contact form. The original had one; the rewrite is 100 % static. Contact is
  by `mailto:` and phone only.
- Cookie banner & cookie policy page. The new site sets no cookies.
- Comments, search, RSS feed. None of these are wired up.
- The 6 legacy WordPress posts (`?p=72,80,160,196,198,202`) from the mirror —
  they were not linked from the live menu and were dropped intentionally.

## Editing workflow

1. Edit `index.org` in Emacs (or any editor — it's plain text).
2. `make serve` to preview locally at http://localhost:8080 (production
   URLs — no prefix).
3. Build for GitHub Pages: `make build CSD_BASE_URL=/csd-preview`. Push.
   The `preview.yml` workflow rebuilds and deploys automatically.
4. Production hosting: only when the Junta has approved, and only by hand.
   See "Deployment" below (`make deploy` or the manual GitHub workflow).

## Deployment

- `.github/workflows/preview.yml` — runs on every push to `main`. Builds
  with `CSD_BASE_URL=/csd-preview` and deploys to GitHub Pages
  (https://mbujosab.github.io/csd-preview/). This is the ONLY automatic
  deployment.
- **Production (ciudadsantodomingo.org, Arsys hosting) is never deployed
  automatically.** Nothing goes to production until the Junta approves the
  revised texts. Two manual paths are prepared:
  - Local: `make deploy-check` (read-only: lists the remote folder) and
    `make deploy` (build without prefix + SFTP mirror with delete). Both call
    `deploy.sh`, which reads the SFTP credentials from `~/.authinfo.gpg`
    (`machine ciudadsantodomingo.org login ciudadsantodomingo.org ...`) and
    asks for the GPG passphrase, so it must be run interactively. The SFTP
    user is `ciudadsantodomingo.org`; the client-area login
    `csd@csdomingo.com` is rejected by the SFTP server.
  - GitHub: `.github/workflows/deploy-production.yml`, `workflow_dispatch`
    only. Input `modo=comprobar` (default) just lists the remote folder;
    `modo=publicar` plus `confirmar=PUBLICAR` uploads. Uses the repo secrets
    `SFTP_HOST`, `SFTP_USER`, `SFTP_PASSWORD`, `SFTP_REMOTE_PATH` and SFTP on
    port 22 via lftp + sshpass. Verified working on 2026-09-25
    (`modo=comprobar` listed the remote folder from a GitHub runner). The
    September "Permission denied" errors were caused by the wrong SFTP user
    (`csd@csdomingo.com` instead of `ciudadsantodomingo.org`) and by
    `sftp -b`, which enables BatchMode and skips password authentication;
    there was no IP restriction at Arsys.
- Credentials for Arsys/SFTP live in `notas.org` (git-ignored). Never copy
  them anywhere else.

## Gotchas

- Output dirs must exist before `org-html-export-to-html`. `csd-publish`
  handles this with `make-directory ... t`; if you bypass it, you'll get
  `"Output file not writable"`.
- `tel:` and `abs:` are *not* native Org link types — they're registered
  via `org-link-set-parameters` in `publish.el`. If you load `index.org`
  in plain Emacs without first loading `publish.el`, those links will
  appear as broken (but only at export time, not when reading).
- The original WordPress site contained UTF-8 characters in filenames
  (e.g. `Gestión-del-agua.pdf`). The import script renames everything to
  ASCII kebab-case to avoid hosting issues.
