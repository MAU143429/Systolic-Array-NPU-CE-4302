#include <iostream>
#include <vector>
#include <cstdint>
#include "../include/PE.h"
using namespace std;

PE::PE() : a(0), b(0), sum(0) {}

void PE::compute() {
    sum += a * b;
}

void PE::resetInputs(){
    a = 0;
    b = 0;
    sum = 0;
}