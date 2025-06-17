#ifndef PE_H
#define PE_H

#include <cstdint>

class PE {
public:
    int16_t a, b, sum, weight;
    PE();
    void compute(int16_t psum_in);
    void resetInputs();
    void setWeight(int16_t w);
    int16_t getWeight();
};

#endif // PE_H
