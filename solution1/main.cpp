#include <iostream>
#include <emmintrin.h>
#include <chrono>
#include <iomanip>

void simd(int* a, int* b, int* result_s, int size) {
    auto start = std::chrono::high_resolution_clock::now();

    for (int i = 0; i <= size - 4; i += 4) {
        __m128i va = _mm_load_si128((__m128i*)(a + i));
        __m128i vb = _mm_load_si128((__m128i*)(b + i));
        __m128i vr = _mm_add_epi32(va, vb);
        _mm_store_si128((__m128i*)(result_s + i), vr);
    }

    for (int i = (size & ~3); i < size; ++i) {
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
    alignas(16) int a[size];
    alignas(16) int b[size];
    for(int i = 1; i < size; i++) {
        a[i] = i;
        b[i] = i;
    }
    int result[size];
    int result_s[size];
    
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
