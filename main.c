#include "trap.h"
#include "print.h"

void KMain(void)
{
   // Initialize the Interrupt Descriptor Table (IDT) before enabling interrupts
   init_idt();
   char* string = "Hello and Welcome!";
   printk("%s\n", string);
}
