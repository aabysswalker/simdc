#include <emmintrin.h>
#include <iostream>
#include <chrono>
#include <iomanip>
#include <cstring>

int loop(char* string, char* substr, int str_length, int sub_length) {
    int result = 0;
    if (sub_length > str_length) return -1;

    auto start = std::chrono::high_resolution_clock::now();

    for (int i = 0; i <= str_length - sub_length; i++) {
        bool found = true;
        for (int j = 0; j < sub_length; j++) {
            if (string[i + j] != substr[j]) {
                found = false;
                break;
            }
        }

        if (found) {
            result++;
        }
    }

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "Loop: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
    return result;
}

int simd(char* string, char* substr, int str_length, int sub_length) {
    if (sub_length > str_length) return -1;
    int result = 0;
    auto start = std::chrono::high_resolution_clock::now();

    for (int i = 0; i <= str_length - sub_length; i++) {
        __m128i str_chunk = _mm_loadu_si128((__m128i*)(string + i));
        __m128i sub_chunk = _mm_loadu_si128((__m128i*)substr);
        int mask = _mm_movemask_epi8(_mm_cmpeq_epi8(str_chunk, sub_chunk));
        if ((mask & ((1 << sub_length) - 1)) == (1 << sub_length) - 1) result++;
    }

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "Simd: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
    return result;
}


int main() {
    char mstr[] = "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf";
    char substr[] = "asd";

    std::cout << loop(mstr, substr, sizeof(mstr) - 1, sizeof(substr) - 1) << std::endl;

    std::cout << simd(mstr, substr, sizeof(mstr) - 1, sizeof(substr) - 1) << std::endl;

    return 0;
}