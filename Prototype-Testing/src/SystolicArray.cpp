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
        int16_t output[N][N];
        void multiply(const int16_t A[N][N]) {
            int16_t psum[N][N] = {0};
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

                        //Sumas parciales desde arriba
                        int16_t psum_in = (i>0) ? peGrid[i - 1][j].sum : 0;
                        //MAC
                        peGrid[i][j].compute(psum_in);
                        
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
                cout << output[i][j] << "\t";
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
    

    int16_t W[N][N] = { 
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

    sa.setWeights(W);
    // Slide window over image
    for (int i = 0; i <= rows - N; ++i) {
        for (int j = 0; j <= cols - N; ++j) {
            int16_t A[N][N];
            // Copy window to A
            for (int x = 0; x < N; ++x)
                for (int y = 0; y < N; ++y)
                    A[x][y] = img.at<uchar>(i + x, j + y);

            sa.resetPEs();
            sa.multiply(A);

            for (int k = 0; k < N; ++k) {
                // Each output channel (column) gets its own output
                // Write to the bottom row of the current window
                if ((i + N - 1) < out.rows && (j + k) < out.cols)
                    out.at<short>(i + N - 1, j + k) += sa.peGrid[N - 1][k].sum;
            }
        }
    }

    //normalize 
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

    //write image
    cv::imwrite("output.png", out8u);
    cout << "Saved result to output.png\n";
    return 0;
}