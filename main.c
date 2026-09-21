void KMain(void)
{
    char* p = (char*)0xb8000; // Point to the VGA text buffer in memory

    p[0] = 'C'; // Write the character 'C' to the first position of the VGA text buffer
    p[1] = 0xa; // Set the attribute byte for the character (white on black)
}
