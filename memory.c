#include "memory.h"
#include "print.h"
#include "debug.h"

static struct FreeMemRegion free_mem_region[50];

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
            free_region_count++;
            total_mem += memory_map[i].length;
        }
    
        printk("%x %uKB %u\n", memory_map[i].address, memory_map[i].length / 1024, memory_map[i].type);
    }

    printk("Total memory is %uMB\n", total_mem/1024/1024);
}
