#include <iostream>
#include <immintrin.h>
#include <chrono>
#include <iomanip>

void simd(int* a, int* b, int* result_s, int size) {
    auto start = std::chrono::high_resolution_clock::now();

    for (int i = 0; i <= size - 8; i += 8) {
        __m256i va = _mm256_load_si256((__m256i*)(a + i));
        __m256i vb = _mm256_load_si256((__m256i*)(b + i));
        __m256i vr = _mm256_add_epi32(va, vb);
        _mm256_store_si256((__m256i*)(result_s + i), vr);
    }

    for (int i = (size & ~7); i < size; ++i) {
        result_s[i] = a[i] + b[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "SIMD addition time: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
}

void loop(int* a, int* b, int* result, int size) {
    auto start = std::chrono::high_resolution_clock::now();

    for (int i = 0; i < size; i++) {
        result[i] = a[i] + b[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "Loop addition time: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
}

int main() {
    const int size = 10000;
    alignas(32) int a[size];
    alignas(32) int b[size];
    for(int i = 0; i < size; i++) {
        a[i] = i;
        b[i] = i;
    }
    alignas(32) int result[size];
    alignas(32) int result_s[size];
    
    simd(a, b, result_s, size);
    loop(a, b, result, size);
    for(int i = 0; i < size; i++) {
        if(result[i] != result_s[i]) {
            std::cout << "addition went wrong!" << std::endl;
            return 0;
        }
    }

    return 0;
}
