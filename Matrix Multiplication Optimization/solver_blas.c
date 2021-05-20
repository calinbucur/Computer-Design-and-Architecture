/*
 * Calin-Andrei Bucur
 * 332CB
 * Tema 2 ASC
 * 2021 Spring
 */
#include "utils.h"
#include "cblas.h"
#include <string.h>

// Need to compute C=A×B×Bt+At×A

double* my_solver(int N, double *A, double *B) {
	// The result matrix
	double *C = malloc(N * N * sizeof(double));
	if (!C)
		return NULL;
	// Initially it's A
	memcpy(C, A, N * N * sizeof(double));
	// Compute At * A and store it in C
	cblas_dtrmm(CblasRowMajor, CblasLeft, CblasUpper, CblasTrans, CblasNonUnit, N, N, 1, A, N, C, N);
	// Auxiliary matrix for the left side of the addition
	double *aux = malloc(N * N * sizeof(double));
	if (!aux)
		return NULL;
	// Initially B
	memcpy(aux, B, N * N * sizeof(double));
	// Compute A * B and store it in aux
	cblas_dtrmm(CblasRowMajor, CblasLeft, CblasUpper, CblasNoTrans, CblasNonUnit, N, N, 1, A, N, aux, N);
	// Compute the final result and store it in C
	cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasTrans, N, N, N, 1, aux, N, B, N, 1, C, N);
	
	free(aux);
	return C;
}
