#include "memory.h"
#include "print.h"
#include "debug.h"
#include "stddef.h"

static void free_region(uint64_t v, uint64_t e);

static struct FreeMemRegion free_mem_region[50];
static struct Page free_memory;
static uint64_t memory_end;
extern char end;

void init_memory(void) {
    int32_t count = *(int32_t *)0x9000; // memory map count location
    uint64_t total_mem = 0;
    struct E820 *memory_map = (struct E820 *)0x9008; // memory map base location
    int free_region_count = 0;

    ASSERT(count <= 50); // Ensure we don't exceed the free_mem_region array size

    for(int32_t i = 0; i < count; i++) {
        if(memory_map[i].type == 1) { // Type 1 indicates available RAM
            free_mem_region[free_region_count].address = memory_map[i].address;
            free_mem_region[free_region_count].length = memory_map[i].length;
            total_mem += memory_map[i].length;
            free_region_count++;
        }
    
        printk("%x %uKB %u\n", memory_map[i].address, memory_map[i].length / 1024, (uint64_t)memory_map[i].type);
    }

    for (int i =0; i < free_region_count; i++) {
        uint64_t vstart = P2V(free_mem_region[i].address);
        uint64_t vend = vstart + free_mem_region[i].length;

        if(vstart < (uint64_t)&end) {
            free_region(vstart,vend);
        }
        if(vstart < (uint64_t)&end) {
            free_region((uint64_t)&end, vend);
        }
    }

    memory_end = (uint64_t)free_memory.next+PAGE_SIZE;
    printk("%x\n", memory_end);
}

static void free_region(uint64_t v, uint64_t e) {
    for(uint64_t start=PA_UP(v); start+PAGE_SIZE <= e; start+=PAGE_SIZE) {
        if(start+PAGE_SIZE <= 0xffff800040000000) {
            kfree(start);
        }
    }
}

void kfree(uint64_t v)
{
    ASSERT(v % PAGE_SIZE == 0);
    ASSERT(v >= (uint64_t)&end);
    ASSERT(v+PAGE_SIZE <= 0xffff800040000000);

    struct Page *page_address = (struct Page*)v;
    page_address->next = free_memory.next;
    free_memory.next = page_address;
}

void* kalloc(void)
{
    struct Page *page_address = free_memory.next;

    if (page_address != NULL) {
        ASSERT((uint64_t)page_address % PAGE_SIZE == 0);
        ASSERT((uint64_t)page_address >= (uint64_t)&end);
        ASSERT((uint64_t)page_address+PAGE_SIZE <= 0xffff800040000000);

        free_memory.next = page_address->next;            
    }
    
    return page_address;
}
