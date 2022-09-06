#!/bin/bash
#
#$ -S /bin/bash
#$ -cwd
#$ -o cachegrind.out
#$ -j y
# Anadir valgrind y gnuplot al path
export PATH=$PATH:/share/apps/tools/valgrind/bin:/share/apps/tools/gnuplot/bin
# Indicar ruta librerías valgrind
export VALGRIND_LIB=/share/apps/tools/valgrind/lib/valgrind
# Pasamos el nombre del script como parámetro
true > cachegrind.out
echo “Ejecutando script cachegrind.sh…”
echo “”
source cachegrind.sh
