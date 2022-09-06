/*
  Computer Architecture, Practice 3.
  Title: Matrix transpose multiplication program for exercise 3.
  Authors: Pedro Urbina and Cesar Ramirez.
*/

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include "arqo3.h"

// In order to see the results for checking if the program works
#define MAX_PRINTABLE_SIZE 0

// Function which cleans all the resources
void cleanup(tipo **a, tipo **b, tipo **bt, tipo **c) {
  freeMatrix(a);
  freeMatrix(b);
  freeMatrix(bt);
  freeMatrix(c);
}

// Function which transposes a matrix
void transpose(tipo **a, tipo**at, int dim) {
  int i, j;
  for(i = 0; i < dim; i++) {
    for(j = 0; j < dim; j++) {
      at[i][j] = a[j][i];
    }
  }
}

// Function that implements the transpose multiplication, and whose execution time will be recorded
void tmultiply(tipo **res, tipo **a, tipo **b, tipo **bt, int dim) {
  int i, j, k;
  transpose(b, bt, dim);
  for(i = 0; i < dim; i++) {
    for(j = 0; j < dim; j++) {
      for(k = 0; k < dim; k++) {
        res[i][j] += a[i][k] * bt[j][k];
      }
    }
  }
}

// Function that prints the matrix, in order to see if the multiplication works
void printMatrix(tipo **a, int dim) {
  int i, j;
  if(a == NULL || dim < 1) return;
  for(i = 0; i < dim; i++) {
    for(j = 0; j < dim; j++) {
      printf("%.2lf ", a[i][j]);
    }
    printf("\n");
  }
}

int main(int argc, char *argv[]) {
  if(argc != 2) {
    fprintf(stderr, "Incorrect arguments. ./%s <matrix_dim>\n", argv[0]);
    return -1;
  }
  int n = atoi(argv[1]);
  if(n < 1) fprintf(stderr, "Invalid argument, the dimension must be bigger than 0.\n");

  tipo **a = generateMatrix(n);
  tipo **b = generateMatrix(n);
  tipo **bt = generateEmptyMatrix(n);
  tipo **c = generateEmptyMatrix(n);
  struct timeval fin,ini;

  if(a == NULL || b == NULL || c == NULL || bt == NULL) {
    fprintf(stderr, "Error when allocating the matrixes.\n");
    cleanup(a, b, bt, c);
    return -1;
  }

  // We measure the time it takes to execute the program
  gettimeofday(&ini,NULL);
  tmultiply(c, a, b, bt, n);
  gettimeofday(&fin,NULL);

  // Execution time is shown and matrix printed if MAX_PRINTABLE_SIZE > 0
  printf("Execution time: %f\n", ((fin.tv_sec*1000000+fin.tv_usec)-(ini.tv_sec*1000000+ini.tv_usec))*1.0/1000000.0);
  if(MAX_PRINTABLE_SIZE > 0) {
    if(n > MAX_PRINTABLE_SIZE) {
      n = MAX_PRINTABLE_SIZE;
      printf("\n\nMatrixes are too big! Only showing the top left %d columns and rows:\n\n", MAX_PRINTABLE_SIZE);
    }
    printMatrix(a,n);
    printf("x \n");
    printMatrix(b,n);
    printf("= \n");
    printMatrix(c,n);
  }

  // Free resources and finish
  cleanup(a,b,bt, c);
  return 0;
}
