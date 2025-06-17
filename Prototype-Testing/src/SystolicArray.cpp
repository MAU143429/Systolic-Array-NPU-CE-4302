#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>
#include <cstdint>
#include "PE.h"
using namespace std;

const int N = 10; // Ensure N matches the kernel size

class SystolicArray {
    public:
        PE peGrid[N][N];
        int16_t outputAccumulator[N][N] = {0}; // Output accumulator

        void multiply(const int16_t A[N][N]) {
            for (int t = 0; t < 3*N -1; ++t) { // Total cycles to process all data
                cout << "Cycle t = " << t + 1 << '\n';

                // Perform systolic array computation
                for (int i = N - 1; i >= 0; --i) {
                    for (int j = N - 1; j >= 0; --j) {
                        // Flow activations horizontally
                        if (j > 0)
                            peGrid[i][j].a = peGrid[i][j - 1].a; // Activation from left
                        else if (t - i >= 0 && t - i < N)
                            peGrid[i][j].a = A[i][t - i]; // Diagonal activation input
                        else
                            peGrid[i][j].a = 0;

                        // Flow weights vertically
                        if (i > 0)
                            peGrid[i][j].b = peGrid[i - 1][j].b; // Weight from above
                        else
                            peGrid[i][j].b = peGrid[i][j].b; // Preloaded weight

                        // Compute partial sum
                        int16_t psum_in = (i > 0) ? peGrid[i - 1][j].sum : 0;
                        peGrid[i][j].compute(psum_in);
                    }
                }

                // Update the output accumulator
                // Shift all rows down
                for (int i = N - 1; i > 0; --i) {
                    for (int j = 0; j < N; ++j) {
                        if(t-j <19)
                            outputAccumulator[i][j] = outputAccumulator[i - 1][j];
                    }
                }
                
                // Update the first row with the last row of peGrid sums + last row of outputAccumulator
                for (int j = 0; j < N; ++j) {
                    if(t-j <19)
                        outputAccumulator[0][j] = peGrid[N - 1][j].sum;
                }
                printAccumulator();

            }
        }

        void processMatrix(const int16_t A[N][N]) {
            multiply(A);
            int16_t normalizedA[N][N];
            int16_t minVal = outputAccumulator[0][0], maxVal = outputAccumulator[0][0];
            cout << "Mutiplied matrix A:\n";
            printAccumulator();
            // Find min and max
            for (int i = 0; i < N; ++i) {
                for (int j = 0; j < N; ++j) {
                    if (outputAccumulator[i][j] < minVal) minVal = outputAccumulator[i][j];
                    if (outputAccumulator[i][j] > maxVal) maxVal = outputAccumulator[i][j];
                }
            }
            
            for (int i = 0; i < N; ++i) {
                for (int j = 0; j < N; ++j) {
                    if (outputAccumulator[i][j] < 0)
                        outputAccumulator[i][j] = static_cast<int16_t>(outputAccumulator[i][j] * 0.1); // Scale down to fit in 8-bit range
                }
            }
            
            //cout << "LReLu matrix A:\n";
            //printAccumulator();

             for (int i = 0; i < N; ++i) {
                for (int j = 0; j < N; ++j) {
                    // Normalize to 0-255 range
                    if (maxVal != minVal) {
                        outputAccumulator[i][j] = static_cast<int16_t>(
                            ((outputAccumulator[i][j] - minVal) * 255) / (maxVal - minVal)
                        );
                    } else {
                        outputAccumulator[i][j] = 0;
                    }
                }
            }
            
        }
        void setWeights(const int16_t weights[N][N]) {
            for (int i = 0; i < N; ++i) {
                for (int j = 0; j < N; ++j)
                    peGrid[i][j].setWeight(weights[i][j]);
            }
        }

        void printResult() {
            cout << "Matrix C = A x B (from PE grid):\n";
            for (int i = 0; i < N; ++i) {
                for (int j = 0; j < N; ++j)
                    cout << "sum: " << peGrid[i][j].sum << " a: " << peGrid[i][j].a << " b: " << peGrid[i][j].b << "\t";
                cout << "\n";
            }
        }

        void printAccumulator() {
            cout << "Output Accumulator:\n";
            for (int i = 0; i < N; ++i) {
                for (int j = 0; j < N; ++j) {
                    cout << outputAccumulator[i][j] << "\t";
                }
                cout << "\n";
            }
        }

        void resetPEs() {
            for (int i = 0; i < N; ++i) {
                for (int j = 0; j < N; ++j)
                    peGrid[i][j].resetInputs();
            }
        }
        void getOutput(int16_t output[N][N]) {
            for (int i = 0; i < N; ++i) {
                for (int j = 0; j < N; ++j) {
                    output[i][j] = outputAccumulator[i][j];
                }
            }
        }
};

// Main function for image processing
int main(int argc, char* argv[]) {
    // Check if the input argument is provided
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <test|input_image_path>\n";
        return -1;
    }

    // Initialize the systolic array
    SystolicArray sa;
    int16_t weights[N][N] = {
        { 1,  2,  3,  4,  5,  5,  4,  3,  2,  1 },
        { 2,  4,  6,  8, 10, 10,  8,  6,  4,  2 },
        { 3,  6,  9, 12, 15, 15, 12,  9,  6,  3 },
        { 4,  8, 12, 16, 20, 20, 16, 12,  8,  4 },
        { 5, 10, 15, 20, 25, 25, 20, 15, 10,  5 },
        { 5, 10, 15, 20, 25, 25, 20, 15, 10,  5 },
        { 4,  8, 12, 16, 20, 20, 16, 12,  8,  4 },
        { 3,  6,  9, 12, 15, 15, 12,  9,  6,  3 },
        { 2,  4,  6,  8, 10, 10,  8,  6,  4,  2 },
        { 1,  2,  3,  4,  5,  5,  4,  3,  2,  1 }
    };
    sa.setWeights(weights); // Set the 10x10 kernel weights

    if (string(argv[1]) == "test") {
        // Use predefined matrix for testing
        /* int16_t inputMatrix[N][N] = {
        {123,  45,  89, 200,  34,  67, 155, 210,  11,  98},
        { 76, 233,  54, 128,  99, 177,  32, 145,  66, 201},
        { 43,  87, 199,  22, 110, 255,   0,  78, 164,  33},
        { 90, 112,  65, 187,  44,  23, 156,  79, 122, 211},
        { 55, 167,  89, 134,  76,  12,  98, 200,  45,  67},
        {188,  77, 143,  22, 109,  34, 165,  88, 199, 111},
        { 20, 154,  76,  43,  87, 222,  33, 145,  66, 178},
        { 99, 122,  45, 167,  89, 200,  11,  34, 155,  76},
        {177,  65,  32, 144,  98, 211,  87,  23, 166,  44},
        { 53, 188,  77, 199, 122,  34, 156,  89, 200,  12}
    }; */
    int16_t inputMatrix[N][N] = {
    {  45, 210,  98, 123,  34,  67, 155,  89, 200,  11},
    { 233,  54, 128,  76,  99, 177,  32, 145,  66, 201},
    {  87, 199,  22,  43, 110, 255,   0,  78, 164,  33},
    { 112,  65, 187,  90,  44,  23, 156,  79, 122, 211},
    { 167,  89, 134,  55,  76,  12,  98, 200,  45,  67},
    {  77, 143,  22, 188, 109,  34, 165,  88, 199, 111},
    { 154,  76,  43,  20,  87, 222,  33, 145,  66, 178},
    { 122,  45, 167,  99,  89, 200,  11,  34, 155,  76},
    {  65,  32, 144, 177,  98, 211,  87,  23, 166,  44},
    { 188,  77, 199,  53, 122,  34, 156,  89, 200,  12}
};

        sa.resetPEs();
        sa.processMatrix(inputMatrix);

        int16_t outputMatrix[N][N];
        sa.getOutput(outputMatrix);

        cout << "Processed matrix:\n";
        for (int i = 0; i < N; ++i) {
            for (int j = 0; j < N; ++j) {
                cout << outputMatrix[i][j] << "\t";
            }
            cout << "\n";
        }
    } else {
        // Load the input image in grayscale
        cv::Mat inputImage = cv::imread(argv[1], cv::IMREAD_GRAYSCALE);
        if (inputImage.empty()) {
            cerr << "Error: Could not load input image from path: " << argv[1] << "\n";
            return -1;
        }

        // Prepare the output image
        cv::Mat outputImage = cv::Mat::zeros(inputImage.size(), CV_8UC1);

        // Process the image in windows of size N x N
        for (int y = 0; y <= inputImage.rows - N; y += N) {
            for (int x = 0; x <= inputImage.cols - N; x += N) {
                int16_t inputMatrix[N][N];
                for (int i = 0; i < N; ++i) {
                    for (int j = 0; j < N; ++j) {
                        inputMatrix[i][j] = inputImage.at<uint8_t>(y + i, x + j);
                    }
                }

                sa.resetPEs();
                sa.processMatrix(inputMatrix);

                int16_t outputMatrix[N][N];
                sa.getOutput(outputMatrix);

                for (int i = 0; i < N; ++i) {
                    for (int j = 0; j < N; ++j) {
                        outputImage.at<uint8_t>(y + i, x + j) = static_cast<uint8_t>(outputMatrix[i][j]);
                    }
                }
            }
        }
/* 
        double minVal, maxVal;
        cv::minMaxLoc(outputImage, &minVal, &maxVal);
        if (maxVal > minVal) {
            outputImage.convertTo(outputImage, CV_8UC1, 255.0 / (maxVal - minVal), -minVal * 255.0 / (maxVal - minVal));
        } */
        // Save the output image
        cv::imwrite("output.jpg", outputImage);

        cout << "Processing complete. Output image saved as 'output.jpg'.\n";
    }

    return 0;
}