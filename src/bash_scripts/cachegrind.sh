# Autores: Pedro Urbina y Cesar Ramirez
# Titulo: Script para obtener resultados ejercicio 2

#!/bin/bash

# variables:
P=7 # = (3 mod 7) + 4
scale=7 # precision en la normalizacion


longExecution=$((1)) # variable que determina si queremos la ejecucion de prueba o la larga

if [ $longExecution = 0 ]; then # vemos si es menor o igual
	echo "PROGRAMA CORTO"
	Ninicio=$((100)) # dimension matriz mas pequeña sobre los que ejecutaremos los programas
	Nfinal=$((300)) # dimension matriz mas grande sobre los que ejecutaremos los programas
	Npaso=$((100)) # salto en el tamaño de las matrices
else
	echo "PROGRAMA LARGO"
	Ninicio=$((2000+512*P)) # dimension matriz mas pequeña sobre los que ejecutaremos los programas
	Nfinal=$((Ninicio+512)) # dimension matriz mas grande sobre los que ejecutaremos los programas
	Npaso=$((64)) # salto en el tamaño de las matrices
fi

srcDir=../	 # directorio con los el codigo y ejecutables
resultsDir=../../results/ex2_results # directorio donde guardaremos los resultados

fDAT_slow=slow_cahegrind.dat # nombre archivo con los resultados numericos del programa slow
fDAT_fast=fast_cahegrind.dat # nombre archivo con los resultados numericos del programa fast
fPNGr=${resultsDir}/cache_lectura.png # nombre archivo donde guardamos el plot de los fallos de lectura
fPNGw=${resultsDir}/cache_escritura.png # nombre archivo donde guardamos el plot de los fallos de escritura
trash=/dev/null # donde enviamos la salida que no queremos mostrar por pantalla

L1size=(1024 2048 4096 8192) # lista de los tamaños de la cache L1
LLsize=8388608 # tamaño de la cache LL: 8 MB
L1ways=1 # asociatividad de la cache L1
LLways=1 # asociatividad de la cache LL
lineSize=64 # tamaño de bloque

# borramos archivos innecesarios
rm -r ${resultsDir}/* > $trash
touch $srcDir/$fDAT_slow $srcDir/$fDAT_fast

# compilamos programas
#pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas
#make slow > $trash
#make fast > $trash
#popd > $trash # volvemos al directorio original

echo "Running from $Ninicio to $Nfinal in steps of $Npaso (both slow and fast programs)."

# bucle que recurre todos los tamaños de la cache L1 que se piden
for i in ${L1size[@]}; do
	echo
	echo
	echo "FIRST LEVEL CACHE SIZE $i BYTES"
	echo
	outFile=${resultsDir}/cachegrind_$i.dat

	#Para cada tamaño de cache ejecutamos cachegrind con cada N
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		echo "Running N: $N out of $Nfinal..."

		pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas
		#Generamos archivos .dat con cachegrind
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_slow \
			--I1=$i,$L1ways,$lineSize --D1=$i,$L1ways,$lineSize \
			--LL=$LLsize,$LLways,$lineSize ./slow $N > ${trash} 2>&1
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_fast \
			--I1=$i,$L1ways,$lineSize --D1=$i,$L1ways,$lineSize \
			--LL=$LLsize,$LLways,$lineSize ./fast $N > ${trash} 2>&1

		#Extraemos los campos relevantes de los resultados de cachegrind
		D1mr_slow=$(cg_annotate $fDAT_slow | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_slow=$(cg_annotate $fDAT_slow | grep 'PROGRAM TOTALS' | awk '{print $8}')
		D1mr_fast=$(cg_annotate $fDAT_fast | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_fast=$(cg_annotate $fDAT_fast | grep 'PROGRAM TOTALS' | awk '{print $8}')
		popd > $trash # volvemos al directorio original

		#Guardamos resultados en archivo y mostramos resultados
		echo "$N	$D1mr_slow	$D1mw_slow	$D1mr_fast	$D1mw_fast" >> $outFile
		echo "N = $N => Slow data cache (D1) misses:	read:	$D1mr_slow;	write:	$D1mw_slow"
		echo "N = $N => Fast data cache (D1) misses:	read:	$D1mr_fast;	write:	$D1mw_fast"
	done
	sed -i -e 's/,//g' ${outFile} # quitamos las comas de los millares
done

# eliminamos archivos inutiles
rm -f $srcDir/$fDAT_slow $srcDir/$fDAT_fast > $trash
#pushd $srcDir > $trash
#make clean > $trash
#popd > $trash


echo
echo
echo "Generating plots..."

gnuplot << END_GNUPLOT
set title "L1 Cache Reading Misses"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
set output "$fPNGr"
cd "${resultsDir}"
plot "cachegrind_${L1size[0]}.dat" using 1:2 with lines lw 2 lc 1 title "slow ${L1size[0]}", \
     "cachegrind_${L1size[0]}.dat" using 1:4 with lines lw 2 lc 2 title "fast ${L1size[0]}", \
     "cachegrind_${L1size[1]}.dat" using 1:2 with lines lw 2 lc 3 title "slow ${L1size[1]}", \
     "cachegrind_${L1size[1]}.dat" using 1:4 with lines lw 2 lc 4 title "fast ${L1size[1]}", \
     "cachegrind_${L1size[2]}.dat" using 1:2 with lines lw 2 lc 5 title "slow ${L1size[2]}", \
     "cachegrind_${L1size[2]}.dat" using 1:4 with lines lw 2 lc 6 title "fast ${L1size[2]}", \
     "cachegrind_${L1size[3]}.dat" using 1:2 with lines lw 2 lc 7 title "slow ${L1size[3]}", \
     "cachegrind_${L1size[3]}.dat" using 1:4 with lines lw 2 lc 8 title "fast ${L1size[3]}"
replot
quit
END_GNUPLOT

gnuplot << END_GNUPLOT
set title "L1 Cache Writting Misses"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
set output "$fPNGw"
cd "${resultsDir}"
plot "cachegrind_${L1size[0]}.dat" using 1:3 with lines lw 2 lc 1 title "slow ${L1size[0]}", \
     "cachegrind_${L1size[0]}.dat" using 1:5 with lines lw 2 lc 2 title "fast ${L1size[0]}", \
     "cachegrind_${L1size[1]}.dat" using 1:3 with lines lw 2 lc 3 title "slow ${L1size[1]}", \
     "cachegrind_${L1size[1]}.dat" using 1:5 with lines lw 2 lc 4 title "fast ${L1size[1]}", \
     "cachegrind_${L1size[2]}.dat" using 1:3 with lines lw 2 lc 5 title "slow ${L1size[2]}", \
     "cachegrind_${L1size[2]}.dat" using 1:5 with lines lw 2 lc 6 title "fast ${L1size[2]}", \
     "cachegrind_${L1size[3]}.dat" using 1:3 with lines lw 2 lc 7 title "slow ${L1size[3]}", \
     "cachegrind_${L1size[3]}.dat" using 1:5 with lines lw 2 lc 8 title "fast ${L1size[3]}"
replot
quit
END_GNUPLOT
