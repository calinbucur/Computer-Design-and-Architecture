/*
 * Calin-Andrei Bucur
 * 322CB
 * Tema 2 ASC
 * 2021 Spring
 */
#include "utils.h"

// Need to compute C=A×B×Bt+At×A

double* my_solver(int N, double *A, double* B) {
	// Compute A transposed 
	double *At = calloc(N * N, sizeof(double));
	register double *line = A;
	register double *res = At;
	for (register int i = 0; i < N; ++i) {
		register double *ins = res + i * N;
		// For upper triangular j can start from i
		for (register int j = i; j < N; ++j) {
			*ins = *(line + j);
			ins += N; 
		}
		line += N;
		res++;
	}
	// Compute B transposed
	double *Bt = malloc(N * N * sizeof(double));
	line = B;
	res = Bt;
	for (register int i = 0; i < N; ++i) {
		register double *ins = res;
		for (register int j = 0; j < N; ++j) {
			*ins = *(line + j);
			ins += N; 
		}
		line += N;
		res++;
	}
	// Compute At * A
	double *AtA = malloc(N * N * sizeof(double));
	line = At;
	res = AtA;
	for (register int i = 0; i < N; ++i) {
		register double *lineAt = At;
		for (register int j = 0; j < N; ++j) {
			register double sum = 0;
			for (register int k = 0; k <= i; ++k) {
				sum += *(line + k) * *(lineAt + k);
			}
			*res = sum;
			lineAt += N;
			res++;
		}
		line += N;
	}
	free(At);
	// Compute A * B
	double *AB = malloc(N * N * sizeof(double));
	line = A;
	res = AB;
	for (register int i = 0; i < N; ++i) {
		register double *lineBt = Bt;
		for (register int j = 0; j < N; ++j) {
			register double sum = 0;
			for (register int k = i; k < N; ++k) {
				sum += *(line + k) * *(lineBt + k);
			}
			*res = sum;
			lineBt += N;
			res++;
		}
		line += N;

	}
	free(Bt);
	// Compute final result
	double *C = AtA;
	line = AB;
	res = C;
	for (register int i = 0; i < N; ++i) {
		register double *lineB = B;
		for (register int j = 0; j < N; ++j) {
			register double sum = 0;
			for (register int k = 0; k < N; k += 4) {
				register double* a = line + k;
				register double* b = lineB + k;
				sum += *a**b + *(a+1)**(b+1) + *(a+2)**(b+2) + *(a+3)**(b+3);
			}
			*res += sum;
			lineB += N;
			res++;
		}
		line += N;
	}
	free(AB);
	return C;
}
