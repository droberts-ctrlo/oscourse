void KMain(void)
{
    char* p = (char*)0xb8000; // VGA text mode buffer address

    p[0] = 'C'; // Character to display
    p[1] = 0xa; // Attribute byte (color)
}
