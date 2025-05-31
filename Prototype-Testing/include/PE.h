#ifndef PE_H
#define PE_H

#include <cstdint>

class PE {
public:
    int16_t a, b, sum;
    PE();
    void compute();
    void resetInputs();
};

#endif // PE_H
