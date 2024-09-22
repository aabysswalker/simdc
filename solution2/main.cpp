#include <iostream>
#include <emmintrin.h>
#include <chrono>
#include <iomanip>
#include <cstdlib>

void simd_addition(int *a, int size) {
    auto start = std::chrono::high_resolution_clock::now();
    
    __m128i res = _mm_setzero_si128();

    for (int i = 0; i <= size - 4; i += 4) {
        __m128i f = _mm_load_si128((__m128i*)(a + i));
        res = _mm_add_epi32(f, res);
    }

    int temp[4];
    _mm_store_si128(reinterpret_cast<__m128i*>(temp), res);
    int total = temp[0] + temp[1] + temp[2] + temp[3];

    for (int i = size - (size % 4); i < size; ++i) {
        total += a[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "SIMD addition time: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
    std::cout << "Result: " << total << std::endl;
}

void loop_addition(int* a, int size) {
    auto start = std::chrono::high_resolution_clock::now();

    int res = 0;

    for (int i = 0; i < size; i++) {
        res += a[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "Loop addition time: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
    std::cout << "Result: " << res << std::endl;
}

int main() {
    const int size = 100000;
    int *a;

    posix_memalign(reinterpret_cast<void**>(&a), 16, size * sizeof(int));

    for(int i = 0; i < size; i++) {
        a[i] = i + 1;
    }

    loop_addition(a, size);
    simd_addition(a, size);

    free(a);

    return 0;
}
