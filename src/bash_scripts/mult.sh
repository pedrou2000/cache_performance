# Autores: Pedro Urbina y Cesar Ramirez
# Titulo: Script para obtener resultados ejercicio 3

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
	repsPerN=1 # repeticion por cada tamaño de matriz
else
	echo "PROGRAMA LARGO"
	Ninicio=$((256+256*P)) # dimension matriz mas pequeña sobre los que ejecutaremos los programas
	Nfinal=$((Ninicio + 256)) # dimension matriz mas grande sobre los que ejecutaremos los programas
	Npaso=$((32)) # salto en el tamaño de las matrices
	repsPerN=5 # repeticion por cada tamaño de matriz
fi

# Arrays para guardar informacion que vamos obteniendo
n=() # almacena los distintos tamaños de matriz
mTime=() # guarda tiempos de la multiplicacion normal
mtTime=() # guarda tiempos de la multiplicacion tranpuesta
mD1mr=() # almacena el numero de fallos cache en lectura de la mult. normal
mD1mw=() # almacena el numero de fallos cache en escritura de la mult. normal
mtD1mr=() # almacena el numero de fallos cache en lectura de la mult. traspuesta
mtD1mw=() # almacena el numero de fallos cache en escritura de la mult. traspuesta

srcDir=../	 # directorio con los el codigo y ejecutables
resultsDir=../../results/ex3_results # directorio donde guardaremos los resultados

fDAT=${resultsDir}/mult.dat # nombre archivo con los resultados numericos
fPNG_cache=${resultsDir}/mult_cache.png # archivo donde guardamos el plot de los fallos de cache
fPNG_time=${resultsDir}/mult_time.png # archivo donde guardamos el plot del tiempo de ejecucion
fDAT_mult=mult_cahegrind.dat # nombre archivo con los resultados numericos del programa slow
fDAT_tmult=tmult_cahegrind.dat # nombre archivo con los resultados numericos del programa fast
trash=/dev/null # donde enviamos la salida que no queremos mostrar por pantalla

# borrar contenidos subdirectorios en los que guardamos resultados
rm -r ${resultsDir}/* > $trash

# compilamos programas
#pushd $srcDir > $trash # entramos en el subdirectorio correcto para compilar los programas
#make mult > $trash
#make tmult > $trash
#popd > $trash # volvemos al directorio original

# inicializacion de los arrays que guardan tiempos medios
j=$((0))
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	mTime[$j]=0
	mtTime[$j]=0
	j=$((j+1))
done

echo
echo "Running from $Ninicio to $Nfinal in steps of $Npaso,\
 $repsPerN times each N (both slow and fast programs)."

pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas

# bucle que recorre ejecuta los programas de forma intercalada para los tamaños deseados
j=$((0))
for ((N = Ninicio, N2 = Ninicio+Npaso ; N2 <= Nfinal ; N += 2*Npaso, N2 += 2*Npaso)); do
	echo "Running $repsPerN times $N and $N2 out of $Nfinal..."
	for ((i = 0 ; i < repsPerN ; i += 1)); do
		mTime[${j}]=$(echo "$(./mult $N | grep 'time' | awk '{print $3}') + ${mTime[$j]}" | bc)
		mTime[$((j+1))]=$(echo "$(./mult $N2 | grep 'time' | awk '{print $3}') + ${mTime[$((j+1))]}" | bc)
		mtTime[${j}]=$(echo "$(./tmult $N | grep 'time' | awk '{print $3}') + ${mtTime[$j]}" | bc)
		mtTime[$((j+1))]=$(echo "$(./tmult $N2 | grep 'time' | awk '{print $3}') + ${mtTime[$((j+1))]}" | bc)
	done
	j=$((j+2))
done
# vemos si el ultimo termino es aun menor que el limite superior y ejecutamos en tal caso
if [ $N -lt $((Nfinal+1)) ]; then # vemos si es menor o igual
	echo "Running $repsPerN times $N out of $Nfinal..."
	for ((i = 0 ; i < repsPerN ; i += 1)); do
		mTime[${j}]=$(echo "$(./mult $N | grep 'time' | awk '{print $3}') + ${mTime[$j]}" | bc)
		mtTime[${j}]=$(echo "$(./tmult $N | grep 'time' | awk '{print $3}') + ${mtTime[$j]}" | bc)
	done
fi

popd > $trash # volvemos al directorio original

# normalizamos y guardamos los resultados obtenidos
j=$((0))
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	mTime[$j]=$(echo "scale=$scale; ${mTime[$j]} / $repsPerN" | bc -l)
	mtTime[$j]=$(echo "scale=$scale; ${mtTime[$j]} / $repsPerN" | bc -l)
	echo "N = $N => Average running time (seconds): mTime: ${mTime[$j]}; mtTime: ${mtTime[$j]}"
	j=$((j+1))
done

echo
echo
echo
echo "Running with cachegrind to test cache misses..."
echo
# ejecutar con cachegrind para ver fallos de cache
j=$((0))
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	echo "Size: $N out of $Nfinal..."

	pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas
	#Generamos archivos .dat con cachegrind
	valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_mult \
		./mult $N > ${trash} 2>&1
	valgrind --tool=cachegrind --cachegrind-out-file=$fDAT_tmult \
		./tmult $N > ${trash} 2>&1

	#Extraemos los campos relevantes de los resultados de cachegrind
	mD1mr[$j]=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $5}')
	mD1mw[$j]=$(cg_annotate $fDAT_mult | grep 'PROGRAM TOTALS' | awk '{print $8}')
	mtD1mr[$j]=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $5}')
	mtD1mw[$j]=$(cg_annotate $fDAT_tmult | grep 'PROGRAM TOTALS' | awk '{print $8}')
	popd > $trash # volvemos al directorio original

	#Guardamos resultados en archivo y mostramos resultados
	echo "N = $N => Normal multiplication data cache (D1) misses:\
		read:	${mD1mr[$j]};	write:	${mD1mw[$j]}"
	echo "N = $N => Transpose multiplication data cache (D1) misses:\
		read:	${mtD1mr[$j]};	write:	${mtD1mw[$j]}"

	echo "$N	${mTime[$j]}	${mD1mr[$j]}	${mD1mw[$j]}\
		${mtTime[$j]}	${mtD1mr[$j]}	${mtD1mw[$j]}" >> $fDAT

	j=$((j+1))
done
sed -i -e 's/,//g' ${fDAT} # quitamos las comas de los millares


# eliminamos archivos inutiles
rm -f $srcDir/$fDAT_mult $srcDir/$fDAT_tmult > $trash
#pushd $srcDir > $trash
#make clean > $trash
#popd > $trash


# usamos gnuplot para generar el grafico correspondiente
echo
echo
echo
echo "Generating plots ..."

# plot del tiempo de ejecucion
gnuplot << END_GNUPLOT
set title "Normal vs Transpose Multiplication Execution Time\n\
 (matrix size: steps of $Npaso, $repsPerN reps per size)"
set ylabel "Execution time (s)"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
set output "${fPNG_time}"
plot "${fDAT}" using 1:2 with lines lw 2 title "normal", \
     "${fDAT}" using 1:5 with lines lw 2 title "transpose"
replot
quit
END_GNUPLOT

# plot de los fallos de cache
gnuplot << END_GNUPLOT
set title "Cache Misses"
set ylabel "Cache Misses"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
set output "${fPNG_cache}"
plot "${fDAT}" using 1:3 with lines lw 2 title "normal read", \
 		 "${fDAT}" using 1:4 with lines lw 2 title "normal write", \
		 "${fDAT}" using 1:6 with lines lw 2 title "transpose read", \
     "${fDAT}" using 1:7 with lines lw 2 title "transpose write"
replot
quit
END_GNUPLOT
