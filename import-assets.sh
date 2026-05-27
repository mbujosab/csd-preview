#!/usr/bin/env bash
# Copia las imágenes y PDFs originales de la copia wget al proyecto nuevo,
# renombrándolos a kebab-case y eligiendo la mejor variante de cada imagen.
#
# Idempotente: se puede ejecutar varias veces.

set -euo pipefail

SRC="../ciudadsantodomingo.org/wp-content/uploads"
IMG="img"
DOCS="docs"

mkdir -p "$IMG" "$DOCS"

cp_img() {  # cp_img <ruta-origen-relativa-a-SRC> <nombre-destino>
  local src="$SRC/$1" dst="$IMG/$2"
  if [[ -f "$src" ]]; then
    cp -f "$src" "$dst"
    echo "img: $1 -> $2"
  else
    echo "FALTA: $src" >&2
  fi
}

cp_doc() {  # cp_doc <ruta-origen-relativa-a-SRC> <nombre-destino>
  local src="$SRC/$1" dst="$DOCS/$2"
  if [[ -f "$src" ]]; then
    cp -f "$src" "$dst"
    echo "doc: $1 -> $2"
  else
    echo "FALTA: $src" >&2
  fi
}

# --- Logos / iconos ---
cp_img 2022/06/Logo-CSD-lr.jpg                                              logo.jpg
cp_img 2022/06/cropped-Logo-CSD-cuadrado-scaled-1-192x192.jpg               favicon.jpg
cp_img 2022/06/Sto-Domingo-aerea-04.png                                     vista-aerea.png

# --- Galería de inicio (urbanización) ---
cp_img 2022/09/Acceso-bandera-scaled.jpg                                    acceso-bandera.jpg
cp_img 2022/09/Acceso-seguridad-scaled.jpg                                  acceso-seguridad.jpg
cp_img 2022/09/Cancha-basket-scaled.jpg                                     cancha-basket.jpg
cp_img 2022/09/Centro-salud-vert-scaled.jpg                                 centro-salud.jpg
cp_img 2022/09/Circuito-scaled.jpg                                          circuito.jpg
cp_img 2022/09/Colegio-scaled.jpg                                           colegio.jpg
cp_img 2022/09/Correos-scaled.jpg                                           correos.jpg
cp_img 2022/09/Iglesia-02-scaled.jpg                                        iglesia.jpg
cp_img 2022/09/PArque-inf-gral-scaled.jpg                                   parque-infantil.jpg
cp_img 2022/09/Plaza-03-scaled.jpg                                          plaza.jpg
cp_img 2022/09/Plaza-frontal-04-scaled.jpg                                  plaza-frontal.jpg
cp_img 2022/09/Plaza-habitada.jpg                                           plaza-habitada.jpg
cp_img 2022/09/PArque-inf-gral-scaled.jpg                                   parque-inf.jpg
cp_img 2022/09/Punto-limpio-02-scaled.jpg                                   punto-limpio.jpg
cp_img 2022/09/Restauracion-02-scaled.jpg                                   restauracion.jpg
cp_img 2022/09/Supuermercado-DIA-scaled.jpg                                 supermercado-dia.jpg
cp_img 2022/09/Tenencia-alcaldia-01-scaled.jpg                              tenencia-alcaldia.jpg
cp_img 2022/09/Urbanizacion-close-scaled.jpg                                urbanizacion.jpg
cp_img 2022/09/Zona-comercial-scaled.jpg                                    zona-comercial.jpg
cp_img 2022/09/BSCH-General-scaled.jpg                                      bsch.jpg
cp_img 2022/09/Gerencia-scaled.jpg                                          gerencia.jpg
cp_img 2022/09/Depuradora-gral-scaled.jpg                                   depuradora-gral.jpg
cp_img 2022/09/Paseo-mascota-close.jpg                                      paseo-mascota.jpg

# --- Asuntos Comunidad ---
cp_img 2022/07/coche-seguridad-1200X852.jpg                                 coche-seguridad.jpg
cp_img 2022/07/Depuradora-1200X852.jpg                                      depuradora.jpg
cp_img 2022/07/Plaza-sol-1200x852-1.jpg                                     plaza-sol.jpg
cp_img 2022/07/Avion-csd-1200x852-1.jpg                                     avion.jpg
cp_img 2022/07/Salida-CSD-scaled.jpg                                        salida-csd.jpg

# --- Asuntos Municipales ---
cp_img 2022/07/autobus-scaled.jpg                                           autobus.jpg
cp_img 2022/07/basura-scaled.jpg                                            basura.jpg
cp_img 2022/07/poda-scaled.jpg                                              poda.jpg
cp_img 2022/07/poda-2-scaled.jpg                                            poda-2.jpg
cp_img 2022/07/claxon-coche.webp                                            claxon.webp
cp_img 2022/07/Policia-Local-Algete-2-scaled.jpeg                           policia-local.jpeg
cp_img 2022/07/Linea_Verde-logo-peq.jpg                                     linea-verde-logo.jpg
cp_img 2022/07/Logo_Ayuntamiento-Algete.png                                 logo-ayto-algete.png
cp_img 2022/07/Algete-Ayto.png                                              algete-ayuntamiento.png
cp_img 2022/06/horario-vuelta-171-madrid-san-sebastian-de-los-reyes-algete-autobuses-interurbanos-web.jpeg horario-bus-171.jpeg

# --- Oficina virtual ---
cp_img 2022/09/Pantallazo-oficina-virtual.jpg                               pantallazo-oficina-virtual.jpg

# --- PDFs ---
cp_doc 2022/09/Consejos-para-vivir....pdf            consejos-vida-comunidad.pdf
cp_doc 2022/07/Gestión-del-agua.pdf                  gestion-del-agua.pdf
cp_doc 2022/06/Seguridad.pdf                         seguridad.pdf
cp_doc 2022/09/Ruido-de-aviones.pdf                  ruido-aviones.pdf
cp_doc 2022/07/BOCM-Ordenanza-Convivencia-Ciudadana.pdf ordenanza-convivencia.pdf
cp_doc 2022/09/Procedimiento-recogida-de-podas.pdf   recogida-podas.pdf
cp_doc 2022/07/Desbroce-de-parcelas.pdf              desbroce-parcelas.pdf
cp_doc 2022/10/Conoce-Ciudad-Santo-Domingo.SB_compressed.pdf conoce-csd.pdf
cp_doc 2022/12/Tutorial-Oficina-Virtual.pdf          tutorial-oficina-virtual.pdf

echo
echo "OK: $(ls $IMG | wc -l) imágenes, $(ls $DOCS | wc -l) PDFs."
