# csd-preview

Web estática de la Comunidad de Propietarios de **Ciudad Santo Domingo**
(Algete, Madrid). Todo el contenido en un único fichero Org-mode
(`index.org`) que se exporta a HTML con `org-publish`.

Repositorio privado, usado por ahora como **preview** desplegada en
GitHub Pages para revisión antes de migrar al hosting definitivo.

## Comandos

| Comando                                | Para qué                                                |
|----------------------------------------|---------------------------------------------------------|
| `make`                                 | Build completo (HTML + assets) en `public/`.            |
| `make serve`                           | Build + servidor local en http://localhost:8080.        |
| `make build CSD_BASE_URL=/csd-preview` | Build con prefijo de URL (para GitHub Pages).           |
| `make clean`                           | Borra `public/`.                                        |

La variable `CSD_BASE_URL` prefija todas las rutas absolutas. Vacía
(por defecto) → producción en la raíz del dominio. `=/csd-preview` →
GitHub Pages en `https://USUARIO.github.io/csd-preview/`.

## Despliegue automático

- `.github/workflows/preview.yml` se ejecuta en cada push a `main`,
  reconstruye el sitio y lo publica en GitHub Pages.
- `.github/workflows/deploy.yml` (latente) está preparado para subir
  por FTP/SFTP al hosting definitivo cuando se configuren los
  *Secrets* y la *Variable* `ENABLE_FTP_DEPLOY=true`.

## Edición

Editar `index.org` (cada subárbol de nivel 1 es una página). Después
`make` y refrescar el navegador. Detalle de arquitectura en
[`CLAUDE.md`](CLAUDE.md).
