#include <iostream>
#include <emmintrin.h>
#include <chrono>
#include <iomanip>

const int ar = 400;
const int ac = 200;
const int br = 200;
const int bc = 400;

void multiplyMatrices(int** a, int** b, int** result) {
    auto start = std::chrono::high_resolution_clock::now();

    for (int i = 0; i < ar; i++) {
        for (int j = 0; j < bc; j++) {
            result[i][j] = 0;
            for (int k = 0; k < ac; k++) {
                result[i][j] += a[i][k] * b[k][j];
            }
        }
    }
    
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "Loop multiplication time: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
}

void multiplyMatricesSIMD(int** a, int** b, int** result) {
    auto start = std::chrono::high_resolution_clock::now();

    for (int i = 0; i < ar; i++) {
        for (int j = 0; j < bc; j++) {
            __m128i sum = _mm_setzero_si128();
            int k = 0;

            for (; k <= ac - 4; k += 4) {
                __m128i vecA = _mm_load_si128(reinterpret_cast<const __m128i*>(&a[i][k]));
                __m128i vecB = _mm_set_epi32(b[k+3][j], b[k+2][j], b[k+1][j], b[k][j]);
                __m128i mul = _mm_mullo_epi16(vecA, vecB);
                sum = _mm_add_epi32(sum, mul);
            }

            int temp[4];
            _mm_store_si128(reinterpret_cast<__m128i*>(temp), sum);
            result[i][j] = temp[0] + temp[1] + temp[2] + temp[3];

            for (; k < ac; k++) {
                result[i][j] += a[i][k] * b[k][j];
            }
        }
    }

    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "SIMD multiplication time: " << std::fixed << std::setprecision(10) << duration.count() << " seconds" << std::endl;
}

void printMatrix(int** a, int r, int c) {
    for(int i = 0; i < r; i++) {
        for(int j = 0; j < c; j++) {
            std::cout << a[i][j] << " ";
        }
        std::cout << std::endl;
    }
    std::cout << std::endl;
}

int main() {
    if (ac != br) {
        std::cout << "Unable to multiply matrices\n";
        return 0;
    }

    int** a;
    int** b;
    int** result;
    int** result_s;

    posix_memalign(reinterpret_cast<void**>(&a), 16, ar * sizeof(int*));
    posix_memalign(reinterpret_cast<void**>(&b), 16, br * sizeof(int*));
    posix_memalign(reinterpret_cast<void**>(&result), 16, ar * sizeof(int*));
    posix_memalign(reinterpret_cast<void**>(&result_s), 16, ar * sizeof(int*));

    for (int i = 0; i < ar; i++) {
        posix_memalign(reinterpret_cast<void**>(&a[i]), 16, ac * sizeof(int));
        posix_memalign(reinterpret_cast<void**>(&result[i]), 16, bc * sizeof(int));
        posix_memalign(reinterpret_cast<void**>(&result_s[i]), 16, bc * sizeof(int));
    }

    for (int i = 0; i < br; i++) {
        posix_memalign(reinterpret_cast<void**>(&b[i]), 16, bc * sizeof(int));
    }


    for (int i = 0; i < ar; i++) {
        for (int j = 0; j < ac; j++) {
            a[i][j] = (i + 1) * (j + 1);
        }
    }

    for (int i = 0; i < br; i++) {
        for (int j = 0; j < bc; j++) {
            b[i][j] = (i + 1) * (j + 2);
        }
    }

    multiplyMatricesSIMD(a, b, result_s);
    multiplyMatrices(a, b, result);

    for (int i = 0; i < ar; i++) {
        delete[] a[i];
        delete[] result[i];
        delete[] result_s[i];
    }
    for (int i = 0; i < br; i++) {
        delete[] b[i];
    }

    delete[] a;
    delete[] b;
    delete[] result;
    delete[] result_s;

    return 0;
}
