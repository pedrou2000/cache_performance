# Ejemplo script, para P3 arq 2019-2020 (modificado)
# Autores: Pedro Urbina y Cesar Ramirez
# Titulo: Script para obtener resultados ejercicio 1

#!/bin/bash

# variables:
P=7 # = (3 mod 7) + 4
scale=7 # precision en la normalizacion

longExecution=$((1)) # variable que determina si queremos la ejecucion de prueba o la larga

if [ $longExecution = 0 ]; then # vemos si es menor o igual
	echo "PROGRAMA CORTO"
	Ninicio=$((100)) # dimension matriz mas pequeña sobre los que ejecutaremos los programas
	Nfinal=$((1000)) # dimension matriz mas grande sobre los que ejecutaremos los programas
	Npaso=$((100)) # salto en el tamaño de las matrices
	repsPerN=10 # repeticion por cada tamaño de matriz
else
	echo "PROGRAMA LARGO"
	Ninicio=$((10000+1024*P)) # dimension matriz mas pequeña sobre los que ejecutaremos los programas
	Nfinal=$((Ninicio + 1024)) # dimension matriz mas grande sobre los que ejecutaremos los programas
	Npaso=$((64)) # salto en el tamaño de las matrices
	repsPerN=20 # repeticion por cada tamaño de matriz
fi

srcDir=src # directorio con los el codigo y ejecutables
resultsDir=ex1_results # directorio donde guardaremos los resultados

fDAT=${resultsDir}/slow_fast_time.dat # nombre archivo con los resultados numericos
fPNG=${resultsDir}/slow_fast_time.png # nombre archivo donde guardamos el plot de gnuplot
trash=/dev/null # donde enviamos la salida que no queremos mostrar por pantalla

fast=() # array que almacena los tiempos medios de ejecucion del programa fast para cada N
slow=() # array que almacena los tiempos medios de ejecucion del programa slow para cada N

# borrar contenidos subdirectorios en los que guardamos resultados
rm -r ${resultsDir}/* > $trash

# compilamos programas
#pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas
#make slow > $trash
#make fast > $trash
#popd > $trash # volvemos al directorio original

# inicializacion de los arrays que guardan tiempos medios
j=$((0))
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	slow[$j]=0
	fast[$j]=0
	j=$((j+1))
done

echo "Running from $Ninicio to $Nfinal in steps of $Npaso, \
	$repsPerN times each N (both slow and fast programs)."

pushd $srcDir > $trash # entramos en el subdirectorio correcto para ejecutar los programas

# bucle que recorre ejecuta los programas de forma intercalada para los tamaños deseados
j=$((0))
for ((N = Ninicio, N2 = Ninicio+Npaso ; N2 <= Nfinal ; N += 2*Npaso, N2 += 2*Npaso)); do
	echo "Running $repsPerN times $N and $N2 out of $Nfinal..."
	for ((i = 0 ; i < repsPerN ; i += 1)); do
		slow[${j}]=$(echo "$(./slow $N | grep 'time' | awk '{print $3}') + ${slow[$j]}" | bc)
		slow[$((j+1))]=$(echo "$(./slow $N2 | grep 'time' | awk '{print $3}') + ${slow[$((j+1))]}" | bc)
		fast[${j}]=$(echo "$(./fast $N | grep 'time' | awk '{print $3}') + ${fast[$j]}" | bc)
		fast[$((j+1))]=$(echo "$(./fast $N2 | grep 'time' | awk '{print $3}') + ${fast[$((j+1))]}" | bc)
	done
	j=$((j+2))
done
# vemos si el ultimo termino es aun menor que el limite superior y ejecutamos en tal caso
if [ $N -lt $((Nfinal+1)) ]; then # vemos si es menor o igual
	echo "Running $repsPerN times $N out of $Nfinal..."
	for ((i = 0 ; i < repsPerN ; i += 1)); do
		slow[${j}]=$(echo "$(./slow $N | grep 'time' | awk '{print $3}') + ${slow[$j]}" | bc)
		fast[${j}]=$(echo "$(./fast $N | grep 'time' | awk '{print $3}') + ${fast[$j]}" | bc)
	done
fi


popd > $trash # volvemos al directorio original

# normalizamos y guardamos los resultados obtenidos
j=$((0))
for ((N = Ninicio ; N <= Nfinal ; N += Npaso)); do
	slow[$j]=$(echo "scale=$scale; ${slow[$j]} / $repsPerN" | bc -l)
	fast[$j]=$(echo "scale=$scale; ${fast[$j]} / $repsPerN" | bc -l)
	echo "$N	${slow[$j]}	${fast[$j]}" >> $fDAT
	echo "N = $N => Average running time (seconds): slow: ${slow[$j]}; fast: ${fast[$j]}"
	j=$((j+1))
done

# eliminamos archivos inutiles
#pushd $srcDir > $trash
#make clean > $trash
#popd > $trash

# usamos gnuplot para generar el grafico correspondiente
echo "Generating plot..."
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Slow-Fast Execution Time\
 (matrix size: steps of $Npaso, $repsPerN reps per size)"
set ylabel "Execution time (s)"
set xlabel "Matrix Size"
set key left top
set grid
set term png size 2000, 1000
set output "${fPNG}"
plot "${fDAT}" using 1:2 with lines lw 2 title "slow", \
     "${fDAT}" using 1:3 with lines lw 2 title "fast"
replot
quit
END_GNUPLOT
