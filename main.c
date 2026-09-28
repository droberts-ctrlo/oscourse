void print(char* str, char attr);

void KMain(void)
{
    print("Welcome to Orion", 0x0a);
}

void print(char* str, char attr) {
    char* p = (char*)0xb8000; // VGA text mode buffer address

    while (*str) {
        *p++ = *str++; // Character to display
        *p++ = attr; // Attribute byte (color)
    }
}
