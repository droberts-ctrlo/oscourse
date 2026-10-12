#include "trap.h"
#include "memory.h"
#include "print.h"

void KMain(void)
{
   // Initialize the Interrupt Descriptor Table (IDT) before enabling interrupts
   printk("Initializing Interrupts...\n");
   init_idt();
   printk("Initializing Memory...\n");
   init_memory();
   printk("System started\n");
}
