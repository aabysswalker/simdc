#include <iostream>
#include <emmintrin.h>
#include <chrono>
#include <iomanip>

void loop_addition(float *a, float *b, float *r, int size) {
    auto start = std::chrono::high_resolution_clock::now();
    
    for(int i = 0; i < size; i++) {
        r[i] = a[i] + b[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "Loop vector addition time: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
}

void loop_dot(float *a, float *b, float *r, int size) {
    auto start = std::chrono::high_resolution_clock::now();
    
    for(int i = 0; i < size; i++) {
        *r = *r + a[i] * b[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "Loop dot product time: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
}

void simd_addition(float *a, float *b, float *r, int size) {
    auto start = std::chrono::high_resolution_clock::now();
    
    for (int i = 0; i <= size - 4; i += 4) {
        __m128 f = _mm_load_ps(a + i);
        __m128 s = _mm_load_ps(b + i);
        __m128 result = _mm_add_ps(f, s);
        _mm_store_ps(r + i, result);
    }

    for (int i = size - (size % 4); i < size; ++i) {
        r[i] = a[i] + b[i];
    }

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "SIMD vector addition time: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
}

void simd_dot(float *a, float *b, float *r, int size) {
    auto start = std::chrono::high_resolution_clock::now();
    
    __m128 sum = _mm_setzero_ps();

    for (int i = 0; i <= size - 4; i += 4) {
        __m128 f = _mm_load_ps(a + i);
        __m128 s = _mm_load_ps(b + i);
        __m128 mul = _mm_mul_ps(f, s);
        sum = _mm_add_ps(sum, mul);
    }

    float temp[4];
    _mm_store_ps(temp, sum);
    float result = temp[0] + temp[1] + temp[2] + temp[3];

    for (int i = (size & ~3); i < size; ++i) {
        result += a[i] * b[i];
    }

    *r = result;

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "SIMD dot product time: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
}

int main() {
    const int size = 100;
    alignas(16) float a[size];
    alignas(16) float b[size];
    for(int i = 0; i < size; i++) {
        a[i] = i + 0.5;
        b[i] = i + 0.5;
    }
    alignas(16) float result_l[size];
    float dot_result_l = 0;
    alignas(16) float result_s[size];
    float dot_result_s = 0;

    loop_addition(a, b, result_l, size);
    simd_addition(a, b, result_s, size);
    for(int i = 0; i < size; i++) {
        if(result_l[i] != result_s[i]) {
            std::cout << "vector addition went wrong!" << std::endl;
            return 0;
        }
    }
    loop_dot(a, b, &dot_result_l, size);
    simd_dot(a, b, &dot_result_s, size);
    if(dot_result_s != dot_result_l) {
        std::cout << dot_result_s << std::endl;
        std::cout << dot_result_l << std::endl;
        std::cout << "dot product went wrong!" << std::endl;
        return 0;
    }

    return 0;
}