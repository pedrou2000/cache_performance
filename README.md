# CACHE AND PERFORMANCE

## 1. Description of the project

The main purpose of this project is to understand how caches can improve the performance of the processor. Different approaches are tested to see how the different types of cache affect the performance of matrix multiplication. We also explore how taking into account the cache architecture of the system running the program can significantly improve performance, that is, how the data access pattern in the algorithms affects performance. Best practices for data access where therefore explored.

The main result of the project is the pdf report outlining the different findings regarding cache utilization and its effects on the overall performance. Different matrices sizes were tested with different algorithms, including the sum of all the elements of huge matrices or matrix multiplication. Different sizes of the different caches were simulated using tools such as valgrind, `cachegrind` and `callgrind` to study the impact in performance. Two programs to perform matrix multiplication and record the time the time it takes were also implemented in the files multiplication.c and tmultiplication.c. The version of the matrix multiplication implemented in the tmultiplication.c file takes into account the cache to achieve better results than the usual matrix multiplication.

Several complex `bash scripts` were created with the intention of achieving the maximum automation possible in the process of performing measurements, taking measurements, storing them and finilly creating the visual results with plots. All these `bash scripts` can be found under in `source/bash_scripts`. Each script has its corresponding 'cluster' version which is used to run the scripts in a cluster on the cloud. 

This project was developed as a one of the tasks for the Computer Architecture course taken during 2019-2020. The project was developed with my colleage César Ramírez. We achieved the maximum grade for our code and mainly our final report. 





## 2. Technologies Used

In order to carry out this project, several tools and programming languages were used. These include:
- `C` as the language of our main programs.
- `gnuplot` in order to plot the results obtained from the code execution.
- `bash scripts` in order to automate the running of the programs, storing the data and the creation of the plots.
- `valgrind`, `cachegrind` and `callgrind` in order to simulate different cache sizes.



## 3. Learning outcomes

These project required a deep level understanding of the technologies used. The main learning outcomes were:
- Understanding the impact that caches have on the performance of algorithms.
- Strategies to make the best use of the advantages that caches offer programmers to make algorithms more efficient and fast.
- The importance of not leaving aside hardware considerations when implementing algorithms.
- Get a deep understanding on how to create `bash scripts` to automate tasks which require the use of different tools as well as the execution of code, making this process faster in the long run and avoiding errors.
- Reinforce my understanding of how to plot raw data with tools like `gnuplot`.
- Using new tools such as `valgrind`, `cachegrind` and `callgrind` for checking statistics about memory usage and simulating different cache sizes.
- Improve my formal wirting skills by creating a report on the main findings of the project.


## 4. How to Install and Run
The main outcome of this project was the report elaborated. However, to run the code to replicate the plots obtained, certain dependencies have to be satisfied. This include:
- `valgrind`, `cachegrind` and `callgrind`
- `gnuplot`
- `lstopo`

When the dependicies are satisfied, the Makefile can be used to build the code. The steps are the following:
1. Open a terminal inside the `src` directory.
2. Run `make all`.
3. You can perform a matrix multimplication of dimension n and get the execution time using the command `./multiplication <n>`.
4. You can alternatively perform the transpose matrix multimplication of dimension n and get the execution time using the command `./tmultiplication <n>`.

### Bash scripts
In order to run the `bash scripts` used to generate the plots, the command `bash <name_of_the_script>` can be run after changing the terminal's directory location to the `bash_scripts` folder (`cd bash_scripts`). These are some short explanations on what each script does:
- `cachegrind.sh`: Runs the `fast` and `slow` programs using different sizes, ways and linesize of the L1 cache to finally plot the results on the relation between the size of the cache and the number of cache misses.
- `mult.sh`: Runs the `multiplication` and `tmultiplication` programs to obtain statistics about the number of cache misses and execution time given different matrix sizes. It also generates plots in order to easaily compare the results.
- `slow_fast_time.sh`: This script creates a plot on the execution times of summing all the elements when varying matrix dimension.
- `ex4.sh`: Very similar to `cachegrind.sh` script, it varies the caches sizes, ways and linesize. It creates different lists with the different things we wanted to vary in order to study the performance when these numbers changed. We chose to vary the L1 size, LL size, L1 number of ways, LL number of ways and the linesize or blocksize (basically everything we are allowed to vary with `cachegrind`). Each thing which varies has an associated list with the corresponding values. Then the script runs the program mult (matrix multiplication) and tmult (transposed matrix multiplication). For every parameter varied a plot is created showing the number of cache writing misses for each dimension of the matrix and another plot showing the number of cache reading misses. On the default configuration it varyies the L1 cache size with the following values: 1KB, 2KB, 4KB, 8KB and 16KB. 


Each script can be adjusted through its different variables, defined at its top. For example, you can run the shell script to create a plot just using the command `bash slow_fast_time.sh`. You can select a long or short execution or you can manually adjust the following parameters at the beginning of the script:
- `Ninicio`: the initial dimension of the matrix to be summed.
- `Npaso`: the increments added to the initial value in each step of the loop.
- `Nfinal`: the final or largest dimension of the matrix to be summed.
- `fDAT`: the name of the file where the data will be saved (it will be automatically created if it does not exist yet).
- `fPNG`: the name of the file where the plot will be saved (it will be automatically created if it does not exist yet).





