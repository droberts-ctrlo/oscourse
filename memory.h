#ifndef _MEMORY_H_
#define _MEMORY_H_

#include "stdint.h"

struct Page {
    struct Page* next;
};

#define PAGE_SIZE (2*1024*1024)
#define PA_UP(v) ((((uint64_t)v+PAGE_SIZE-1)>>21)<<21)
#define PA_DOWN(v) (((uint64_t)v>>21)<<21)
#define P2V(p) ((uint64_t)(p)+0xffff800000000000)
#define V2P(v) ((uint64_t)(v)-0xffff800000000000)

struct E820 {
    uint64_t address;
    uint64_t length;
    uint32_t type;
} __attribute__((packed));

struct FreeMemRegion {
    uint64_t address;
    uint64_t length;
};

void init_memory(void);
void* kalloc(void);
void kfree(uint64_t v);

#endif
