#!/bin/bash
#
#$ -S /bin/bash
#$ -cwd
#$ -o ex4.out
#$ -j y
# Anadir valgrind y gnuplot al path
export PATH=$PATH:/share/apps/tools/valgrind/bin:/share/apps/tools/gnuplot/bin
# Indicar ruta librerías valgrind
export VALGRIND_LIB=/share/apps/tools/valgrind/lib/valgrind
# Pasamos el nombre del script como parámetro
true > ex4.out
echo “Ejecutando script ex4.sh…”
echo “”
source ex4.sh
