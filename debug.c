#include "debug.h"
#include "print.h"

void error_check(const char *file, uint64_t line) {
    printk("Assertion failed in file %s at line: %u\n", file, line);

    while (1) {}
}
