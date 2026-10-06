#ifndef _PRINT_H_
#define _PRINT_H_

#define LINE_SIZE 160 // Number of characters per line on the screen

struct ScreenBuffer {
    char* buffer; // Pointer to the screen buffer
    int column;   // Current column position on the screen
    int row;      // Current row position on the screen
};

// Function to print formatted output to the screen
int printk(const char *format, ...);

#endif
