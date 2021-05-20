/*
 * Calin-Andrei Bucur
 * 322CB
 * Tema 2 ASC
 * 2021 Spring
 */
#include "utils.h"

// Need to compute C=A×B×Bt+At×A

// Computes the transpose of a matrix
double* transpose(int N,  double *M) {
	double *Mt = malloc(N * N * sizeof(double));
	if (!Mt)
		return NULL;
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			Mt[j * N + i] = M[i * N + j];
		}
	}
	return Mt;
}

// Multiplies upper triangular matrix A with matrix B
double* mul_uptr(int N, double *A, double* B) {
	double *res = calloc(N * N, sizeof(double));
	if (!res)
		return NULL;
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			// It's sufficient for K to start from the current row
			for (int k = i; k < N; k++) {
				res[i * N + j] += A[i * N + k] * B[k * N + j];
			}
		}
	}
	return res;
}

// Multiplies lower triangular matrix A with matrix B
double* mul_lotr(int N, double *A, double* B) {
	double *res = calloc(N * N, sizeof(double));
	if (!res)
		return NULL;
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			// It's sufficient for K to go up to the current row
			for (int k = 0; k <= i; k++) {
				res[i * N + j] += A[i * N + k] * B[k * N + j];
			}
		}
	}
	return res;
}

// General case multiplication
double* mul_gen(int N, double *A, double* B) {
	double *res = calloc(N * N, sizeof(double));
	if (!res)
		return NULL;
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			for (int k = 0; k < N; k++) {
				res[i * N + j] += A[i * N + k] * B[k * N + j];
			}
		}
	}
	return res;
}

double* my_solver(int N, double *A, double* B) {
	// Compute the transposed matrices At and Bt
	double *At = transpose(N, A);
	double *Bt = transpose(N, B);
	// Compute At * A
	double *AtA = mul_lotr(N, At, A);
	// At is no longer needed
	free(At);
	// Compute A * B * Bt
	double *AB = mul_uptr(N, A, B);
	double *ABBt = mul_gen(N, AB, Bt);
	// AB and Bt are no longer needed
	free(Bt);
	free(AB);
	// Compute the final addition storing the result in ABBt
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			ABBt[i * N + j] += AtA[i * N + j];
		}
	}
	
	free(AtA);
	return ABBt;
}
