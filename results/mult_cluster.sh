#!/bin/bash
#
#$ -S /bin/bash
#$ -cwd
#$ -o mult.out
#$ -j y
# Anadir valgrind y gnuplot al path
export PATH=$PATH:/share/apps/tools/valgrind/bin:/share/apps/tools/gnuplot/bin
# Indicar ruta librerías valgrind
export VALGRIND_LIB=/share/apps/tools/valgrind/lib/valgrind
# Pasamos el nombre del script como parámetro
true > mult.out
echo “Ejecutando script mult.sh…”
echo “”
source mult.sh
