# Autores: Pedro Urbina y Cesar Ramirez
# Titulo: Script para obtener resultados ejercicio 4

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
  Ninicio=$((1024)) # dimension matriz mas pequeña sobre los que ejecutaremos los programas
  Nfinal=$((Ninicio + 512)) # dimension matriz mas grande sobre los que ejecutaremos los programas
  Npaso=$((64)) # salto en el tamaño de las matrices
fi

srcDir=../ # directorio con los el codigo y ejecutables
resultsDir=../../results/ex4_results # directorio donde guardaremos los resultados

fDAT_mult=mult_cahegrind.dat # nombre archivo con los resultados numericos del programa mult
fDAT_tmult=tmult_cahegrind.dat # nombre archivo con los resultados numericos del programa tmult
nombrePlotsL=fallos_lectura_var_ # prefijo plots fallos lectura
nombrePlotsW=fallos_escritura_var_ # prefijo pllots fallo escritura
# nombre archivos donde guardamos los plots con los resultados de fallos de cache
fPNGr=(${nombrePlotsL}L1size.png ${nombrePlotsL}LLsize.png ${nombrePlotsL}L1ways.png\
  ${nombrePlotsL}LLways.png ${nombrePlotsL}lineSize.png)
fPNGw=(${nombrePlotsW}L1size.png ${nombrePlotsW}LLsize.png ${nombrePlotsW}L1ways.png\
  ${nombrePlotsW}LLways.png ${nombrePlotsW}lineSize.png)
trash=/dev/null # donde enviamos la salida que no queremos mostrar por pantalla

L1size=4096 # tamaño default de la cache L1: 4KB
LLsize=8388608 # tamaño default de la cache LL: 8 MB
L1ways=4 # asociatividad default de la cache L1
LLways=4 # asociatividad default de la cache LL
lineSize=64 # tamanio deafult de bloque

# listas de los valores por los que probaremos las diferentes configuranciones
L1sizeL=($((L1size/4)) $((L1size/2)) $((L1size)) $((L1size*2)) $((L1size*4)))
LLsizeL=($((LLsize/4)) $((LLsize/2)) $((LLsize)) $((LLsize*2)) $((LLsize*4)))
L1waysL=($((L1ways/4)) $((L1ways/2)) $((L1ways)) $((L1ways*2)) $((L1ways*4)))
LLwaysL=($((LLways/4)) $((LLways/2)) $((LLways)) $((LLways*2)) $((LLways*4)))
lineSizeL=($((lineSize/2)) $((lineSize)) $((lineSize*2)) $((lineSize*4)) $((lineSize*8)))

listA=(L1size LLsize L1ways LLways lineSize)
listB=(L1sizeL LLsizeL L1waysL LLwaysL lineSizeL)

# borramos archivos innecesarios
rm -r ${resultsDir}/* > $trash
touch $srcDir/$fDAT_mult $srcDir/$fDAT_tmult

# compilamos programas
#pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas
#make mult > $trash
#make tmult > $trash
#popd > $trash # volvemos al directorio original



# TESTING HOW VARYING L1 CACHE SIZE AFFECTS READ AND WRITE CACHE MISSES

echo
echo "TESTING HOW VARYING L1 CACHE SIZE AFFECTS READ AND WRITE CACHE MISSES"
echo
echo

echo "Running from $Ninicio to $Nfinal in steps of $Npaso (both mult and tmult programs)."

# bucle que recurre todos los tamaños de la cache L1 que se piden
for i in ${L1sizeL[@]}; do
	echo
	echo
	echo "FIRST LEVEL CACHE SIZE $i BYTES"
	echo
	outFile=${resultsDir}/cachegrind_${listA[0]}_$i.dat

	#Para cada tamaño de cache ejecutamos cachegrind con cada N
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		echo "Running N: $N out of $Nfinal..."

		pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas
		#Generamos archivos .dat con cachegrind
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_mult \
			--I1=$i,$L1ways,$lineSize --D1=$i,$L1ways,$lineSize \
			--LL=$LLsize,$LLways,$lineSize ./mult $N > ${trash} 2>&1
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_tmult \
			--I1=$i,$L1ways,$lineSize --D1=$i,$L1ways,$lineSize \
			--LL=$LLsize,$LLways,$lineSize ./tmult $N > ${trash} 2>&1

		#Extraemos los campos relevantes de los resultados de cachegrind
		D1mr_mult=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_mult=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $8}')
		D1mr_tmult=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_tmult=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $8}')
		popd > $trash # volvemos al directorio original

		#Guardamos resultados en archivo y mostramos resultados
		echo "$N	$D1mr_mult	$D1mw_mult	$D1mr_tmult	$D1mw_tmult" >> $outFile
		echo "N = $N => mult data cache (D1) misses:	read:	$D1mr_mult;	write:	$D1mw_mult"
		echo "N = $N => tmult data cache (D1) misses:	read:	$D1mr_tmult;	write:	$D1mw_tmult"
	done
	sed -i -e 's/,//g' ${outFile} # quitamos las comas de los millares
done

# eliminamos archivos inutiles
rm -f $srcDir/$fDAT_mult $srcDir/$fDAT_tmult > $trash


echo
echo
echo "Generating plots..."

gnuplot << END_GNUPLOT
set title "L1 Cache Reading Misses, Varying L1 Cache Size"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
cd "${resultsDir}"
set output "${fPNGr[0]}"
plot "cachegrind_${listA[0]}_${L1sizeL[0]}.dat" using 1:2 with lines lw 2 lc 1 title "mult ${L1sizeL[0]}", \
     "cachegrind_${listA[0]}_${L1sizeL[0]}.dat" using 1:4 with lines lw 2 lc 2 title "tmult ${L1sizeL[0]}", \
     "cachegrind_${listA[0]}_${L1sizeL[1]}.dat" using 1:2 with lines lw 2 lc 3 title "mult ${L1sizeL[1]}", \
     "cachegrind_${listA[0]}_${L1sizeL[1]}.dat" using 1:4 with lines lw 2 lc 4 title "tmult ${L1sizeL[1]}", \
     "cachegrind_${listA[0]}_${L1sizeL[2]}.dat" using 1:2 with lines lw 2 lc 5 title "mult ${L1sizeL[2]}", \
     "cachegrind_${listA[0]}_${L1sizeL[2]}.dat" using 1:4 with lines lw 2 lc 6 title "tmult ${L1sizeL[2]}", \
     "cachegrind_${listA[0]}_${L1sizeL[3]}.dat" using 1:2 with lines lw 2 lc 7 title "mult ${L1sizeL[3]}", \
     "cachegrind_${listA[0]}_${L1sizeL[3]}.dat" using 1:4 with lines lw 2 lc 8 title "tmult ${L1sizeL[3]}", \
     "cachegrind_${listA[0]}_${L1sizeL[4]}.dat" using 1:2 with lines lw 2 lc 9 title "mult ${L1sizeL[4]}", \
     "cachegrind_${listA[0]}_${L1sizeL[4]}.dat" using 1:4 with lines lw 2 lc 10 title "tmult ${L1sizeL[4]}"
replot
quit
END_GNUPLOT

gnuplot << END_GNUPLOT
set title "L1 Cache Writting Misses, Varying L1 Cache Size"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
cd "${resultsDir}"
set output "${fPNGw[0]}"
plot "cachegrind_${listA[0]}_${L1sizeL[0]}.dat" using 1:3 with lines lw 2 lc 1 title "mult ${L1sizeL[0]}", \
     "cachegrind_${listA[0]}_${L1sizeL[0]}.dat" using 1:5 with lines lw 2 lc 2 title "tmult ${L1sizeL[0]}", \
     "cachegrind_${listA[0]}_${L1sizeL[1]}.dat" using 1:3 with lines lw 2 lc 3 title "mult ${L1sizeL[1]}", \
     "cachegrind_${listA[0]}_${L1sizeL[1]}.dat" using 1:5 with lines lw 2 lc 4 title "tmult ${L1sizeL[1]}", \
     "cachegrind_${listA[0]}_${L1sizeL[2]}.dat" using 1:3 with lines lw 2 lc 5 title "mult ${L1sizeL[2]}", \
     "cachegrind_${listA[0]}_${L1sizeL[2]}.dat" using 1:5 with lines lw 2 lc 6 title "tmult ${L1sizeL[2]}", \
     "cachegrind_${listA[0]}_${L1sizeL[3]}.dat" using 1:3 with lines lw 2 lc 7 title "mult ${L1sizeL[3]}", \
     "cachegrind_${listA[0]}_${L1sizeL[3]}.dat" using 1:5 with lines lw 2 lc 8 title "tmult ${L1sizeL[3]}", \
     "cachegrind_${listA[0]}_${L1sizeL[4]}.dat" using 1:3 with lines lw 2 lc 9 title "mult ${L1sizeL[4]}", \
     "cachegrind_${listA[0]}_${L1sizeL[4]}.dat" using 1:5 with lines lw 2 lc 10 title "tmult ${L1sizeL[4]}"
replot
quit
END_GNUPLOT





# TESTING HOW VARYING LL CACHE SIZE AFFECTS READ AND WRITE CACHE MISSES

echo
echo
echo
echo
echo
echo "TESTING HOW VARYING LL CACHE SIZE AFFECTS READ AND WRITE CACHE MISSES"
echo
echo

touch $srcDir/$fDAT_mult $srcDir/$fDAT_tmult
echo "Running from $Ninicio to $Nfinal in steps of $Npaso (both mult and tmult programs)."

# bucle que recurre todos los tamaños de la cache L1 que se piden
for i in ${LLsizeL[@]}; do
	echo
	echo
	echo "LAST LEVEL CACHE SIZE $i BYTES"
	echo
	outFile=${resultsDir}/cachegrind_${listA[1]}_$i.dat

	#Para cada tamaño de cache ejecutamos cachegrind con cada N
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		echo "Running N: $N out of $Nfinal..."

		pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas
		#Generamos archivos .dat con cachegrind
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_mult \
			--I1=$L1size,$L1ways,$lineSize --D1=$L1size,$L1ways,$lineSize \
			--LL=$i,$LLways,$lineSize ./mult $N > ${trash} 2>&1
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_tmult \
			--I1=$L1size,$L1ways,$lineSize --D1=$L1size,$L1ways,$lineSize \
			--LL=$i,$LLways,$lineSize ./tmult $N > ${trash} 2>&1

		#Extraemos los campos relevantes de los resultados de cachegrind
		D1mr_mult=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_mult=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $8}')
		D1mr_tmult=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_tmult=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $8}')
		popd > $trash # volvemos al directorio original

		#Guardamos resultados en archivo y mostramos resultados
		echo "$N	$D1mr_mult	$D1mw_mult	$D1mr_tmult	$D1mw_tmult" >> $outFile
		echo "N = $N => mult data cache (D1) misses:	read:	$D1mr_mult;	write:	$D1mw_mult"
		echo "N = $N => tmult data cache (D1) misses:	read:	$D1mr_tmult;	write:	$D1mw_tmult"
	done
	sed -i -e 's/,//g' ${outFile} # quitamos las comas de los millares
done

# eliminamos archivos inutiles
rm -f $srcDir/$fDAT_mult $srcDir/$fDAT_tmult > $trash


echo
echo
echo "Generating plots..."

gnuplot << END_GNUPLOT
set title "L1 Cache Reading Misses, Varying LL Cache Size"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
cd "${resultsDir}"
set output "${fPNGr[1]}"
plot "cachegrind_${listA[1]}_${LLsizeL[0]}.dat" using 1:2 with lines lw 2 lc 1 title "mult ${LLsizeL[0]}", \
     "cachegrind_${listA[1]}_${LLsizeL[0]}.dat" using 1:4 with lines lw 2 lc 2 title "tmult ${LLsizeL[0]}", \
     "cachegrind_${listA[1]}_${LLsizeL[1]}.dat" using 1:2 with lines lw 2 lc 3 title "mult ${LLsizeL[1]}", \
     "cachegrind_${listA[1]}_${LLsizeL[1]}.dat" using 1:4 with lines lw 2 lc 4 title "tmult ${LLsizeL[1]}", \
     "cachegrind_${listA[1]}_${LLsizeL[2]}.dat" using 1:2 with lines lw 2 lc 5 title "mult ${LLsizeL[2]}", \
     "cachegrind_${listA[1]}_${LLsizeL[2]}.dat" using 1:4 with lines lw 2 lc 6 title "tmult ${LLsizeL[2]}", \
     "cachegrind_${listA[1]}_${LLsizeL[3]}.dat" using 1:2 with lines lw 2 lc 7 title "mult ${LLsizeL[3]}", \
     "cachegrind_${listA[1]}_${LLsizeL[3]}.dat" using 1:4 with lines lw 2 lc 8 title "tmult ${LLsizeL[3]}", \
     "cachegrind_${listA[1]}_${LLsizeL[4]}.dat" using 1:2 with lines lw 2 lc 9 title "mult ${LLsizeL[4]}", \
     "cachegrind_${listA[1]}_${LLsizeL[4]}.dat" using 1:4 with lines lw 2 lc 10 title "tmult ${LLsizeL[4]}"
replot
quit
END_GNUPLOT

gnuplot << END_GNUPLOT
set title "L1 Cache Writting Misses, Varying LL Cache Size"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
cd "${resultsDir}"
set output "${fPNGw[1]}"
plot "cachegrind_${listA[1]}_${LLsizeL[0]}.dat" using 1:3 with lines lw 2 lc 1 title "mult ${LLsizeL[0]}", \
     "cachegrind_${listA[1]}_${LLsizeL[0]}.dat" using 1:5 with lines lw 2 lc 2 title "tmult ${LLsizeL[0]}", \
     "cachegrind_${listA[1]}_${LLsizeL[1]}.dat" using 1:3 with lines lw 2 lc 3 title "mult ${LLsizeL[1]}", \
     "cachegrind_${listA[1]}_${LLsizeL[1]}.dat" using 1:5 with lines lw 2 lc 4 title "tmult ${LLsizeL[1]}", \
     "cachegrind_${listA[1]}_${LLsizeL[2]}.dat" using 1:3 with lines lw 2 lc 5 title "mult ${LLsizeL[2]}", \
     "cachegrind_${listA[1]}_${LLsizeL[2]}.dat" using 1:5 with lines lw 2 lc 6 title "tmult ${LLsizeL[2]}", \
     "cachegrind_${listA[1]}_${LLsizeL[3]}.dat" using 1:3 with lines lw 2 lc 7 title "mult ${LLsizeL[3]}", \
     "cachegrind_${listA[1]}_${LLsizeL[3]}.dat" using 1:5 with lines lw 2 lc 8 title "tmult ${LLsizeL[3]}", \
     "cachegrind_${listA[1]}_${LLsizeL[4]}.dat" using 1:3 with lines lw 2 lc 9 title "mult ${LLsizeL[4]}", \
     "cachegrind_${listA[1]}_${LLsizeL[4]}.dat" using 1:5 with lines lw 2 lc 10 title "tmult ${LLsizeL[4]}"
replot
quit
END_GNUPLOT




# TESTING HOW VARYING L1 CACHE WAYS AFFECTS READ AND WRITE CACHE MISSES

echo
echo
echo
echo
echo
echo "TESTING HOW VARYING L1 CACHE SIZE WAYS READ AND WRITE CACHE MISSES"
echo
echo

touch $srcDir/$fDAT_mult $srcDir/$fDAT_tmult
echo "Running from $Ninicio to $Nfinal in steps of $Npaso (both mult and tmult programs)."

# bucle que recurre todos los tamaños de la cache L1 que se piden
for i in ${L1waysL[@]}; do
	echo
	echo
	echo "FIRST LEVEL CACHE: $i WAYS"
	echo
	outFile=${resultsDir}/cachegrind_${listA[2]}_$i.dat

	#Para cada tamaño de cache ejecutamos cachegrind con cada N
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		echo "Running N: $N out of $Nfinal..."

		pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas
		#Generamos archivos .dat con cachegrind
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_mult \
			--I1=$L1size,$i,$lineSize --D1=$L1size,$i,$lineSize \
			--LL=$LLsize,$LLways,$lineSize ./mult $N > ${trash} 2>&1
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_tmult \
			--I1=$L1size,$i,$lineSize --D1=$L1size,$i,$lineSize \
			--LL=$LLsize,$LLways,$lineSize ./tmult $N > ${trash} 2>&1

		#Extraemos los campos relevantes de los resultados de cachegrind
		D1mr_mult=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_mult=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $8}')
		D1mr_tmult=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_tmult=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $8}')
		popd > $trash # volvemos al directorio original

		#Guardamos resultados en archivo y mostramos resultados
		echo "$N	$D1mr_mult	$D1mw_mult	$D1mr_tmult	$D1mw_tmult" >> $outFile
		echo "N = $N => mult data cache (D1) misses:	read:	$D1mr_mult;	write:	$D1mw_mult"
		echo "N = $N => tmult data cache (D1) misses:	read:	$D1mr_tmult;	write:	$D1mw_tmult"
	done
	sed -i -e 's/,//g' ${outFile} # quitamos las comas de los millares
done

# eliminamos archivos inutiles
rm -f $srcDir/$fDAT_mult $srcDir/$fDAT_tmult > $trash


echo
echo
echo "Generating plots..."

gnuplot << END_GNUPLOT
set title "L1 Cache Reading Misses, Varying L1 Cache Number Of Ways"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
cd "${resultsDir}"
set output "${fPNGr[2]}"
plot "cachegrind_${listA[2]}_${L1waysL[0]}.dat" using 1:2 with lines lw 2 lc 1 title "mult ${L1waysL[0]}", \
     "cachegrind_${listA[2]}_${L1waysL[0]}.dat" using 1:4 with lines lw 2 lc 2 title "tmult ${L1waysL[0]}", \
     "cachegrind_${listA[2]}_${L1waysL[1]}.dat" using 1:2 with lines lw 2 lc 3 title "mult ${L1waysL[1]}", \
     "cachegrind_${listA[2]}_${L1waysL[1]}.dat" using 1:4 with lines lw 2 lc 4 title "tmult ${L1waysL[1]}", \
     "cachegrind_${listA[2]}_${L1waysL[2]}.dat" using 1:2 with lines lw 2 lc 5 title "mult ${L1waysL[2]}", \
     "cachegrind_${listA[2]}_${L1waysL[2]}.dat" using 1:4 with lines lw 2 lc 6 title "tmult ${L1waysL[2]}", \
     "cachegrind_${listA[2]}_${L1waysL[3]}.dat" using 1:2 with lines lw 2 lc 7 title "mult ${L1waysL[3]}", \
     "cachegrind_${listA[2]}_${L1waysL[3]}.dat" using 1:4 with lines lw 2 lc 8 title "tmult ${L1waysL[3]}", \
     "cachegrind_${listA[2]}_${L1waysL[4]}.dat" using 1:2 with lines lw 2 lc 9 title "mult ${L1waysL[4]}", \
     "cachegrind_${listA[2]}_${L1waysL[4]}.dat" using 1:4 with lines lw 2 lc 10 title "tmult ${L1waysL[4]}"
replot
quit
END_GNUPLOT

gnuplot << END_GNUPLOT
set title "L1 Cache Writting Misses, Varying L1 Cache Number Of Ways"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
cd "${resultsDir}"
set output "${fPNGw[2]}"
plot "cachegrind_${listA[2]}_${L1waysL[0]}.dat" using 1:3 with lines lw 2 lc 1 title "mult ${L1waysL[0]}", \
     "cachegrind_${listA[2]}_${L1waysL[0]}.dat" using 1:5 with lines lw 2 lc 2 title "tmult ${L1waysL[0]}", \
     "cachegrind_${listA[2]}_${L1waysL[1]}.dat" using 1:3 with lines lw 2 lc 3 title "mult ${L1waysL[1]}", \
     "cachegrind_${listA[2]}_${L1waysL[1]}.dat" using 1:5 with lines lw 2 lc 4 title "tmult ${L1waysL[1]}", \
     "cachegrind_${listA[2]}_${L1waysL[2]}.dat" using 1:3 with lines lw 2 lc 5 title "mult ${L1waysL[2]}", \
     "cachegrind_${listA[2]}_${L1waysL[2]}.dat" using 1:5 with lines lw 2 lc 6 title "tmult ${L1waysL[2]}", \
     "cachegrind_${listA[2]}_${L1waysL[3]}.dat" using 1:3 with lines lw 2 lc 7 title "mult ${L1waysL[3]}", \
     "cachegrind_${listA[2]}_${L1waysL[3]}.dat" using 1:5 with lines lw 2 lc 8 title "tmult ${L1waysL[3]}", \
     "cachegrind_${listA[2]}_${L1waysL[4]}.dat" using 1:3 with lines lw 2 lc 9 title "mult ${L1waysL[4]}", \
     "cachegrind_${listA[2]}_${L1waysL[4]}.dat" using 1:5 with lines lw 2 lc 10 title "tmult ${L1waysL[4]}"
replot
quit
END_GNUPLOT




# TESTING HOW VARYING LL CACHE WAYS AFFECTS READ AND WRITE CACHE MISSES

echo
echo
echo
echo
echo
echo "TESTING HOW VARYING LL CACHE WAYS AFFECTS READ AND WRITE CACHE MISSES"
echo
echo

touch $srcDir/$fDAT_mult $srcDir/$fDAT_tmult
echo "Running from $Ninicio to $Nfinal in steps of $Npaso (both mult and tmult programs)."

# bucle que recurre todos los tamaños de la cache L1 que se piden
for i in ${LLwaysL[@]}; do
	echo
	echo
	echo "LAST LEVEL CACHE: $i WAYS"
	echo
	outFile=${resultsDir}/cachegrind_${listA[3]}_$i.dat

	#Para cada tamaño de cache ejecutamos cachegrind con cada N
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		echo "Running N: $N out of $Nfinal..."

		pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas
		#Generamos archivos .dat con cachegrind
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_mult \
			--I1=$L1size,$L1ways,$lineSize --D1=$L1size,$L1ways,$lineSize \
			--LL=$LLsize,$i,$lineSize ./mult $N > ${trash} 2>&1
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_tmult \
			--I1=$L1size,$L1ways,$lineSize --D1=$L1size,$L1ways,$lineSize \
			--LL=$LLsize,$i,$lineSize ./tmult $N > ${trash} 2>&1

		#Extraemos los campos relevantes de los resultados de cachegrind
		D1mr_mult=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_mult=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $8}')
		D1mr_tmult=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_tmult=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $8}')
		popd > $trash # volvemos al directorio original

		#Guardamos resultados en archivo y mostramos resultados
		echo "$N	$D1mr_mult	$D1mw_mult	$D1mr_tmult	$D1mw_tmult" >> $outFile
		echo "N = $N => mult data cache (D1) misses:	read:	$D1mr_mult;	write:	$D1mw_mult"
		echo "N = $N => tmult data cache (D1) misses:	read:	$D1mr_tmult;	write:	$D1mw_tmult"
	done
	sed -i -e 's/,//g' ${outFile} # quitamos las comas de los millares
done

# eliminamos archivos inutiles
rm -f $srcDir/$fDAT_mult $srcDir/$fDAT_tmult > $trash


echo
echo
echo "Generating plots..."

gnuplot << END_GNUPLOT
set title "L1 Cache Reading Misses, Varying LL Cache Number Of Ways"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
cd "${resultsDir}"
set output "${fPNGr[3]}"
plot "cachegrind_${listA[3]}_${LLwaysL[0]}.dat" using 1:2 with lines lw 2 lc 1 title "mult ${LLwaysL[0]}", \
     "cachegrind_${listA[3]}_${LLwaysL[0]}.dat" using 1:4 with lines lw 2 lc 2 title "tmult ${LLwaysL[0]}", \
     "cachegrind_${listA[3]}_${LLwaysL[1]}.dat" using 1:2 with lines lw 2 lc 3 title "mult ${LLwaysL[1]}", \
     "cachegrind_${listA[3]}_${LLwaysL[1]}.dat" using 1:4 with lines lw 2 lc 4 title "tmult ${LLwaysL[1]}", \
     "cachegrind_${listA[3]}_${LLwaysL[2]}.dat" using 1:2 with lines lw 2 lc 5 title "mult ${LLwaysL[2]}", \
     "cachegrind_${listA[3]}_${LLwaysL[2]}.dat" using 1:4 with lines lw 2 lc 6 title "tmult ${LLwaysL[2]}", \
     "cachegrind_${listA[3]}_${LLwaysL[3]}.dat" using 1:2 with lines lw 2 lc 7 title "mult ${LLwaysL[3]}", \
     "cachegrind_${listA[3]}_${LLwaysL[3]}.dat" using 1:4 with lines lw 2 lc 8 title "tmult ${LLwaysL[3]}", \
     "cachegrind_${listA[3]}_${LLwaysL[4]}.dat" using 1:2 with lines lw 2 lc 9 title "mult ${LLwaysL[4]}", \
     "cachegrind_${listA[3]}_${LLwaysL[4]}.dat" using 1:4 with lines lw 2 lc 10 title "tmult ${LLwaysL[4]}"
replot
quit
END_GNUPLOT

gnuplot << END_GNUPLOT
set title "L1 Cache Writting Misses, Varying LL Cache Number Of Ways"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
cd "${resultsDir}"
set output "${fPNGw[3]}"
plot "cachegrind_${listA[3]}_${LLwaysL[0]}.dat" using 1:3 with lines lw 2 lc 1 title "mult ${LLwaysL[0]}", \
     "cachegrind_${listA[3]}_${LLwaysL[0]}.dat" using 1:5 with lines lw 2 lc 2 title "tmult ${LLwaysL[0]}", \
     "cachegrind_${listA[3]}_${LLwaysL[1]}.dat" using 1:3 with lines lw 2 lc 3 title "mult ${LLwaysL[1]}", \
     "cachegrind_${listA[3]}_${LLwaysL[1]}.dat" using 1:5 with lines lw 2 lc 4 title "tmult ${LLwaysL[1]}", \
     "cachegrind_${listA[3]}_${LLwaysL[2]}.dat" using 1:3 with lines lw 2 lc 5 title "mult ${LLwaysL[2]}", \
     "cachegrind_${listA[3]}_${LLwaysL[2]}.dat" using 1:5 with lines lw 2 lc 6 title "tmult ${LLwaysL[2]}", \
     "cachegrind_${listA[3]}_${LLwaysL[3]}.dat" using 1:3 with lines lw 2 lc 7 title "mult ${LLwaysL[3]}", \
     "cachegrind_${listA[3]}_${LLwaysL[3]}.dat" using 1:5 with lines lw 2 lc 8 title "tmult ${LLwaysL[3]}", \
     "cachegrind_${listA[3]}_${LLwaysL[4]}.dat" using 1:3 with lines lw 2 lc 9 title "mult ${LLwaysL[4]}", \
     "cachegrind_${listA[3]}_${LLwaysL[4]}.dat" using 1:5 with lines lw 2 lc 10 title "tmult ${LLwaysL[4]}"
replot
quit
END_GNUPLOT




# TESTING HOW VARYING BLOCK SIZE AFFECTS READ AND WRITE CACHE MISSES

echo
echo
echo
echo
echo
echo "TESTING HOW VARYING BLOCK SIZE AFFECTS READ AND WRITE CACHE MISSES"
echo
echo

touch $srcDir/$fDAT_mult $srcDir/$fDAT_tmult
echo "Running from $Ninicio to $Nfinal in steps of $Npaso (both mult and tmult programs)."

# bucle que recurre todos los tamaños de la cache L1 que se piden
for i in ${lineSizeL[@]}; do
	echo
	echo
	echo "LINE SIZE (BLOCK SIZE): $i "
	echo
	outFile=${resultsDir}/cachegrind_${listA[4]}_$i.dat

	#Para cada tamaño de cache ejecutamos cachegrind con cada N
	for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
		echo "Running N: $N out of $Nfinal..."

		pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas
		#Generamos archivos .dat con cachegrind
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_mult \
			--I1=$L1size,$L1ways,$i --D1=$L1size,$L1ways,$i \
			--LL=$LLsize,$LLways,$i ./mult $N > ${trash} 2>&1
		valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_tmult \
			--I1=$L1size,$L1ways,$i --D1=$L1size,$L1ways,$i \
			--LL=$LLsize,$LLways,$i ./tmult $N > ${trash} 2>&1

		#Extraemos los campos relevantes de los resultados de cachegrind
		D1mr_mult=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_mult=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $8}')
		D1mr_tmult=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $5}')
		D1mw_tmult=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $8}')
		popd > $trash # volvemos al directorio original

		#Guardamos resultados en archivo y mostramos resultados
		echo "$N	$D1mr_mult	$D1mw_mult	$D1mr_tmult	$D1mw_tmult" >> $outFile
		echo "N = $N => mult data cache (D1) misses:	read:	$D1mr_mult;	write:	$D1mw_mult"
		echo "N = $N => tmult data cache (D1) misses:	read:	$D1mr_tmult;	write:	$D1mw_tmult"
	done
	sed -i -e 's/,//g' ${outFile} # quitamos las comas de los millares
done

# eliminamos archivos inutiles
rm -f $srcDir/$fDAT_mult $srcDir/$fDAT_tmult > $trash
#pushd $srcDir > $trash
#make clean > $trash
#popd > $trash

echo
echo
echo "Generating plots..."

gnuplot << END_GNUPLOT
set title "L1 Cache Reading Misses, Varying Line Size (Block Size)"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
cd "${resultsDir}"
set output "${fPNGr[4]}"
plot "cachegrind_${listA[4]}_${lineSizeL[0]}.dat" using 1:2 with lines lw 2 lc 1 title "mult ${lineSizeL[0]}", \
     "cachegrind_${listA[4]}_${lineSizeL[0]}.dat" using 1:4 with lines lw 2 lc 2 title "tmult ${lineSizeL[0]}", \
     "cachegrind_${listA[4]}_${lineSizeL[1]}.dat" using 1:2 with lines lw 2 lc 3 title "mult ${lineSizeL[1]}", \
     "cachegrind_${listA[4]}_${lineSizeL[1]}.dat" using 1:4 with lines lw 2 lc 4 title "tmult ${lineSizeL[1]}", \
     "cachegrind_${listA[4]}_${lineSizeL[2]}.dat" using 1:2 with lines lw 2 lc 5 title "mult ${lineSizeL[2]}", \
     "cachegrind_${listA[4]}_${lineSizeL[2]}.dat" using 1:4 with lines lw 2 lc 6 title "tmult ${lineSizeL[2]}", \
     "cachegrind_${listA[4]}_${lineSizeL[3]}.dat" using 1:2 with lines lw 2 lc 7 title "mult ${lineSizeL[3]}", \
     "cachegrind_${listA[4]}_${lineSizeL[3]}.dat" using 1:4 with lines lw 2 lc 8 title "tmult ${lineSizeL[3]}", \
     "cachegrind_${listA[4]}_${lineSizeL[4]}.dat" using 1:2 with lines lw 2 lc 9 title "mult ${lineSizeL[4]}", \
     "cachegrind_${listA[4]}_${lineSizeL[4]}.dat" using 1:4 with lines lw 2 lc 10 title "tmult ${lineSizeL[4]}"
replot
quit
END_GNUPLOT

gnuplot << END_GNUPLOT
set title "L1 Cache Writting Misses, Varying Line Size (Block Size)"
set ylabel "Cache misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
cd "${resultsDir}"
set output "${fPNGw[4]}"
plot "cachegrind_${listA[4]}_${lineSizeL[0]}.dat" using 1:3 with lines lw 2 lc 1 title "mult ${lineSizeL[0]}", \
     "cachegrind_${listA[4]}_${lineSizeL[0]}.dat" using 1:5 with lines lw 2 lc 2 title "tmult ${lineSizeL[0]}", \
     "cachegrind_${listA[4]}_${lineSizeL[1]}.dat" using 1:3 with lines lw 2 lc 3 title "mult ${lineSizeL[1]}", \
     "cachegrind_${listA[4]}_${lineSizeL[1]}.dat" using 1:5 with lines lw 2 lc 4 title "tmult ${lineSizeL[1]}", \
     "cachegrind_${listA[4]}_${lineSizeL[2]}.dat" using 1:3 with lines lw 2 lc 5 title "mult ${lineSizeL[2]}", \
     "cachegrind_${listA[4]}_${lineSizeL[2]}.dat" using 1:5 with lines lw 2 lc 6 title "tmult ${lineSizeL[2]}", \
     "cachegrind_${listA[4]}_${lineSizeL[3]}.dat" using 1:3 with lines lw 2 lc 7 title "mult ${lineSizeL[3]}", \
     "cachegrind_${listA[4]}_${lineSizeL[3]}.dat" using 1:5 with lines lw 2 lc 8 title "tmult ${lineSizeL[3]}", \
     "cachegrind_${listA[4]}_${lineSizeL[4]}.dat" using 1:3 with lines lw 2 lc 9 title "mult ${lineSizeL[4]}", \
     "cachegrind_${listA[4]}_${lineSizeL[4]}.dat" using 1:5 with lines lw 2 lc 10 title "tmult ${lineSizeL[4]}"
replot
quit
END_GNUPLOT

# comment if you need the .dat files
rm -f $resultsDir/*.dat > $trash
