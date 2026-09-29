#include "trap.h"

void KMain(void)
{
   // Initialize the Interrupt Descriptor Table (IDT) before enabling interrupts
   init_idt();
}