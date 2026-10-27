#include "trap.h"
#include "print.h"
#include "memory.h"

void KMain(void)
{
   init_idt();
   init_memory();
   init_kvm();
}
