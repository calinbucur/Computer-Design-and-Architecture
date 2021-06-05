// Calin Bucur 332CB
// Tema 3 ASC

#ifndef _HASHCPU_
#define _HASHCPU_

#include <vector>

using namespace std;

#define cudaCheckError() { \
	cudaError_t e=cudaGetLastError(); \
	if(e!=cudaSuccess) { \
		cout << "Cuda failure " << __FILE__ << ", " << __LINE__ << ", " << cudaGetErrorString(e); \
		exit(0); \
	 }\
}


// Structure representing a key-value pair
typedef struct {
	uint32_t key;
	uint32_t value;
} Data;

/**
 * Class GpuHashTable to implement functions
 */

class GpuHashTable
{
	private:
		int size; // Current size
		int capacity; // Maximum size
		Data *arr; // Actual table

	public:
		GpuHashTable(int size);
		void reshape(int sizeReshape);
		
		bool insertBatch(int *keys, int* values, int numKeys);
		int* getBatch(int* key, int numItems);
	
		~GpuHashTable();
};

#endif

