#include <iostream>
#include <vector>
#include <cstdint>
#include "../include/PE.h"
using namespace std;

PE::PE() : a(0), b(0), sum(0) {}

void PE::compute(int16_t psum_in) {
    sum = psum_in + a * weight;
}

void PE::resetInputs(){
    a = 0;
    b = 0;
    sum = 0;
}
void PE::setWeight(int16_t w) {
    weight = w;
}
int16_t PE::getWeight() {
    return weight;
}
