// Calin Bucur 332CB
// Tema 3 ASC

#include <iostream>
#include <limits.h>
#include <stdlib.h>
#include <ctime>
#include <sstream>
#include <string>
#include "test_map.hpp"
#include "gpu_hashtable.hpp"

using namespace std;

// Number of threads in a block
#define BLOCK_SIZE 256

// Hashing function
// Got it from the internet
// Apparently the distribution is quite uniform for reasons beyond my understanding
__device__ int hash_func(int key) {
	int hash = key;
	hash = ((hash >> 16) ^ hash) * 0x45d9f3b;
    hash = ((hash >> 16) ^ hash) * 0x45d9f3b;
    hash = (hash >> 16) ^ hash;
    return hash;
}

// Kernel that rehashes every key-value pair from the old table and inserts it into the new one
__global__ void rehash (Data *old_arr, Data *new_arr, int old_size, int new_size) {
	// Get the index of the key-value pair the current thread should rehash
	unsigned int idx = threadIdx.x + blockDim.x * blockIdx.x;
	// Check if the index is within bounds and if there is a pair at that index
	if (idx < old_size && old_arr[idx].key != 0) {
		// Compute the new hash
		int hash = hash_func(old_arr[idx].key);
		// Get the position where it should be inserted
		hash %= new_size;
		// Atomically check if the position is free and insert the key
		atomicCAS(&new_arr[hash].key, 0, old_arr[idx].key);
		// Check if the key was inserted
		if (new_arr[hash].key == old_arr[idx].key) {
			// Insert the value
			new_arr[hash].value = old_arr[idx].value;
		} else { // Liniar probing
			// Get the next posible position
			hash++;
			// Loop until the pair was inserted
			// We have the guarantee the loop will break at some point
			while(1) {
				// Atomically check if the position is free and insert the key
				atomicCAS(&new_arr[hash].key, 0, old_arr[idx].key);
				// Check if the key was inserted
				if (new_arr[hash].key == old_arr[idx].key) {
					// Insert the value
					new_arr[hash].value = old_arr[idx].value;
					// Break the loop
					return;
				} else {
					// Move to the next hash
					// If the end of the table was reached start from 0
					hash = (hash + 1) % new_size;
				}
			}
		}
	}
}

// Kernel that inserts a batch of key-value pairs in the table
// Uses liniar probing for collisions
__global__ void insert(Data *arr, int capacity, int *keys, int *values, int numKeys, int *existing) {
	// Get the index of the key-value pair the current thread should insert
	unsigned int idx = threadIdx.x + blockDim.x * blockIdx.x;
	// Check if the index is in bounds
	if (idx < numKeys) {
		Data pair;
		pair.key = keys[idx];
		pair.value = values[idx];
		// Compute the hash
		int hash = hash_func(pair.key);
		// Get the position
		hash %= capacity;
		// Check if the key is already inserted at that position
		if (arr[hash].key == pair.key) {
			// Update the value
			arr[hash].value = pair.value;
			// Decrement the number of pairs inserted
			atomicSub(existing, 1); // Didn't use atomicDec because it had a weird condition
		}
		else {
			// Atomically check if the position is free and insert the key
			atomicCAS(&arr[hash].key, 0, pair.key);
			if (arr[hash].key == pair.key) {
				// Insert the value
				arr[hash].value = pair.value;
			}
			else { // Liniar probing
				// Get the next possible position
				hash++;
				// Loop until the pair was inserted
				// We have the guarantee the loop will break at some point
				while(1) {
					// If the key a;ready exists at that position
					if (arr[hash].key == pair.key) {
						// Update the value
						arr[hash].value = pair.value;
						// Decrement the number of pairs inserted
						atomicSub(existing, 1);
						return;
					} else {
						// Atomically check if the position is free and insert the key
						atomicCAS(&arr[hash].key, 0, pair.key);
						// Check if the key was inserted
						if (arr[hash].key == pair.key) {
							// Insert the value
							arr[hash].value = pair.value;
							return;
						}
						else {
							// Go to the next position
							hash = (hash + 1) % capacity;
						}
					}
				}
			}
		}
	}
}

// Kernel that gets the values for a batch of keys
__global__ void get(Data *arr, int *keys, int *values, int capacity, int numKeys) {
	// Get the index of the key the current thread should look for
	unsigned int idx = threadIdx.x + blockDim.x * blockIdx.x;
	// Check that the index is in bounds
	if (idx < numKeys) {
		int key = keys[idx]; // Get the key
		// Compute the hash
		int hash = hash_func(key);
		// Get the position
		hash %= capacity;
		// Check if the key is there
		if (arr[hash].key == key) {
			// Get the value
			values[idx] = arr[hash].value;
		}
		else { // Liniar probing
			hash++;
			// Check element by element until the key is found
			while (1) {
				if (arr[hash].key == key) {
					values[idx] = arr[hash].value;
					break;
				}
				else {
					hash = (hash + 1) % capacity;
				}
			}
		}
	}
}

// Hash Table constructor
GpuHashTable::GpuHashTable(int size) {
	this->capacity = size;
	this->size = 0; // Initially the table is empty
	// Allocate the table in the VRAM
	glbGpuAllocator->_cudaMalloc((void **)&this->arr, this->capacity * sizeof(Data));
	cudaCheckError();
	// Set all the positions as empty (a.k.a zero)
	cudaMemset(this->arr, 0, this->capacity * sizeof(Data));
}

// Hash Table destructor
GpuHashTable::~GpuHashTable() {
	glbGpuAllocator->_cudaFree(this->arr);
}

// Resizes the table
void GpuHashTable::reshape(int numBucketsReshape) {
	Data *new_arr;
	// Allocate the new array of the desired size
	glbGpuAllocator->_cudaMalloc((void **)&new_arr, numBucketsReshape * sizeof(Data));
	cudaCheckError();
	// Initialize all the positions as empty
	cudaMemset(new_arr, 0, numBucketsReshape * sizeof(Data));
	cudaCheckError();
	// Calculate the number of blocks necessary
	int block_num = this->capacity / BLOCK_SIZE;
	if (this->capacity % BLOCK_SIZE)
		block_num++;
	// Call the kernel
	rehash<<<block_num, BLOCK_SIZE>>>(this->arr, new_arr, this->capacity, numBucketsReshape);
	cudaDeviceSynchronize();
	cudaCheckError();
	// Free the old table
	glbGpuAllocator->_cudaFree(this->arr);
	cudaCheckError();
	// Assign the new table
	this->arr = new_arr;
	// Update the capacity
	this->capacity = numBucketsReshape;
}

// Inserts a batch of key-value pairs
bool GpuHashTable::insertBatch(int *keys, int* values, int numKeys) {
	// If the capacity would be exceeded
	if (this->size + numKeys >= this->capacity) {
		// Double the capacity
		this->reshape((this->size + numKeys) * 2);
	}
	// Calculate the number of blocks necessary
	int block_num = numKeys / BLOCK_SIZE;
	if (numKeys % BLOCK_SIZE)
		block_num++;
	int *GPU_keys;
	int *GPU_values;
	int *GPU_numKeys;
	// Allocate arrays for the keys and values to be inserted
	glbGpuAllocator->_cudaMalloc((void **)&GPU_keys, numKeys * sizeof(int));
	cudaCheckError();
	glbGpuAllocator->_cudaMalloc((void **)&GPU_values, numKeys * sizeof(int));
	cudaCheckError();
	// Allocate a pointer for the number of keys inserted
	// This will be updated with the number of keys that were actually inserted (not updated)
	glbGpuAllocator->_cudaMalloc((void **)&GPU_numKeys, sizeof(int));
	cudaCheckError();
	// Copy the data into the GPU arrays
	cudaMemcpy(GPU_keys, keys, numKeys * sizeof(int), cudaMemcpyHostToDevice);
	cudaCheckError();
	cudaMemcpy(GPU_values, values, numKeys * sizeof(int), cudaMemcpyHostToDevice);
	cudaCheckError();
	cudaMemcpy(GPU_numKeys, &numKeys, sizeof(int), cudaMemcpyHostToDevice);
	cudaCheckError();
	// Call the kernel
	insert<<<block_num, BLOCK_SIZE>>>(this->arr, this->capacity, GPU_keys, GPU_values, numKeys, GPU_numKeys);
	cudaDeviceSynchronize();
	cudaCheckError();
	// Get the number of inserted keys
	cudaMemcpy(&numKeys, GPU_numKeys, sizeof(int), cudaMemcpyDeviceToHost);
	cudaCheckError();
	// Update the size
	this->size += numKeys;
	// Free the gpu arrays
	glbGpuAllocator->_cudaFree(GPU_keys);
	cudaCheckError();
	glbGpuAllocator->_cudaFree(GPU_values);
	cudaCheckError();
	glbGpuAllocator->_cudaFree(GPU_numKeys);
	cudaCheckError();
	return true;
}

// Gets a batch of values corresponding to the given keys
int* GpuHashTable::getBatch(int* keys, int numKeys) {
	// Calculate the necessary number of blocks
	int block_num = numKeys / BLOCK_SIZE;
	if (numKeys % BLOCK_SIZE)
		block_num++;
	int *GPU_keys;
	int *GPU_values;
	// Allocate GPU arrays for the keys and values
	glbGpuAllocator->_cudaMalloc((void **)&GPU_keys, numKeys * sizeof(int));
	cudaCheckError();
	glbGpuAllocator->_cudaMalloc((void **)&GPU_values, numKeys * sizeof(int));
	cudaCheckError();
	// Copy the keys
	cudaMemcpy(GPU_keys, keys, numKeys * sizeof(int), cudaMemcpyHostToDevice);
	cudaCheckError();
	// Call the kernel
	get<<<block_num, BLOCK_SIZE>>>(this->arr, GPU_keys, GPU_values, this->capacity, numKeys);
	cudaDeviceSynchronize();
	cudaCheckError();
	// Allocate an array for the values
	int *values = (int*)malloc(numKeys * sizeof(int));
	// Copy the values from the GPU
	cudaMemcpy(values, GPU_values, numKeys * sizeof(int), cudaMemcpyDeviceToHost);
	cudaCheckError();
	// Free the GPU arrays
	glbGpuAllocator->_cudaFree(GPU_keys);
	cudaCheckError();
	glbGpuAllocator->_cudaFree(GPU_values);
	cudaCheckError();
	return values;
}
