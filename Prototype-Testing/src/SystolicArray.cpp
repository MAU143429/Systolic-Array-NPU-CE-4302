#include <opencv2/opencv.hpp>
#include <iostream>
#include <vector>
#include <cstdint>
#include "PE.h"
using namespace std;

const int N = 10;
class SystolicArray {
    public:
        PE peGrid[N][N];

        void multiply(const int16_t A[N][N], const int16_t B[N][N]){
            for (int t = 0; t <= 2 * N; ++t){
                //cout << "t = " << t << '\n';
                for(int i = N -1; i >= 0; --i){
                    for(int j = N -1; j >= 0; --j){
                        //izquierda a derecha
                        if (j > 0)
                            //a viene de la izquierda, para j>0
                            peGrid[i][j].a = peGrid[i][j - 1].a;
                        else if (t - i >= 0 && t - i < N)
                            //a viene de A para j=0, en forma diagonal (t-i)
                            peGrid[i][j].a = A[i][t - i];
                        else
                            peGrid[i][j].a = 0;

                        //arriba a abajo
                        if ( i > 0)
                            peGrid[i][j].b = peGrid[i - 1][j].b;
                        else if (t - j >= 0 && t - j < N)
                            //b viene de B para i=0, en forma diagonal (t-j)
                            peGrid[i][j].b = B[t - j][j];
                        else
                            peGrid[i][j].b = 0;
                        //MAC
                        peGrid[i][j].compute();
                    }
                }
                /** 
                // Print first row and first column a and b after each t
                cout << "First row (a, b): ";
                for (int j = 0; j < N; ++j)
                    cout << "(" << peGrid[0][j].a << "," << peGrid[0][j].b << ") ";
                cout << "\nFirst column (a, b): ";
                for (int i = 0; i < N; ++i)
                    cout << "(" << peGrid[i][0].a << "," << peGrid[i][0].b << ") ";
                cout << "\n";*/
        }
}

        void printResult() {
        cout << "Matrix C = A x B (from PE grid):\n";
        for (int i = 0; i < N; ++i) {
            for (int j = 0; j < N; ++j)
                cout << peGrid[i][j].sum << "\t";
        cout << "\n";
            }
        }
        void resetPEs() {
        for (int i = 0; i < N; ++i) {
            for (int j = 0; j < N; ++j)
                peGrid[i][j].resetInputs();
        }
    }
    
    
};

int main() {
    string imagePath;
    cout << "Enter the path to the grayscale image: ";
    cin >> imagePath;

    // Load grayscale image
    cv::Mat img = cv::imread(imagePath, cv::IMREAD_GRAYSCALE);
    if (img.empty()) {
        cerr << "Image not found!\n";
        return 1;
    }

    int rows = img.rows;
    int cols = img.cols;

    // Output image (same size, zeroed)
    cv::Mat out = cv::Mat::zeros(rows, cols, CV_16S);
    /** 
    int16_t B[N][N] = { 
        { 0,  0, -1,  0,  0},
        { 0, -1, -2, -1,  0},
        {-1, -2, 16, -2, -1},
        { 0, -1, -2,  1,  0},
        { 0,  0, -1,  0,  0} };
    */

    int16_t B[N][N] = { 
        { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
        { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
        { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
        { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
        { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1} };
    SystolicArray sa;

    // Slide window over image
    for (int i = 0; i <= rows - N; ++i) {
        for (int j = 0; j <= cols - N; ++j) {
            int16_t A[N][N];
            // Copy window to A
            for (int x = 0; x < N; ++x)
                for (int y = 0; y < N; ++y)
                    A[x][y] = img.at<uchar>(i + x, j + y);

            sa.resetPEs();
            sa.multiply(A, B);

            // Store the center PE sum in the output image
            out.at<short>(i + N/2, j + N/2) = sa.peGrid[N/2][N/2].sum;
        }
    }

    // Normalize and convert to 8-bit for saving
    double minVal, maxVal;
    cv::minMaxLoc(out, &minVal, &maxVal);
    cv::Mat out8u;
    out.convertTo(out8u, CV_8U, 255.0/(maxVal-minVal), -minVal*255.0/(maxVal-minVal));

    // Apply Leaky ReLU with alpha=0.1
    for (int i = 0; i < out.rows; ++i) {
        for (int j = 0; j < out.cols; ++j) {
            short& val = out.at<short>(i, j);
            if (val < 0)
                val = static_cast<short>(val * 0.2);
        }
    }

    cv::imwrite("output.png", out8u);
    cout << "Saved result to output.png\n";
    return 0;
}