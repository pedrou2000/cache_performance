#!/bin/bash
#
#$ -S /bin/bash
#$ -cwd
#$ -o slow_fast_time.out
#$ -j y
# Anadir valgrind y gnuplot al path
export PATH=$PATH:/share/apps/tools/valgrind/bin:/share/apps/tools/gnuplot/bin
# Indicar ruta librerías valgrind
export VALGRIND_LIB=/share/apps/tools/valgrind/lib/valgrind
# Pasamos el nombre del script como parámetro
true > slow_fast_time.out #> /dev/null
echo “Ejecutando script slow_fast_time.sh…”
echo “”
source slow_fast_time.sh
