#include "trap.h"
#include "print.h"

void KMain(void)
{
   // Initialize the Interrupt Descriptor Table (IDT) before enabling interrupts
   printk("Initializing Interrupts...\n");
   init_idt();
   printk("System started\n");
}
