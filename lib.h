#ifndef _LIB_H_
#define _LIB_H_

void memset(void* buffer, char value, int size);
void memmove(void* dest, const void* src, int size);
void memcpy(void* dest, const void* src, int size);
int memcmp(const void* buffer1, const void* buffer2, int size);

#endif
