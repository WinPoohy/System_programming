// array.h
#ifndef ARRAY_H
#define ARRAY_H

typedef struct {
    unsigned long* data;
    unsigned long capacity;
    unsigned long size;
} Array;

Array* create_array();
void free_array(Array* arr);
void add_to_end(Array* arr, unsigned long value);
unsigned long remove_from_start(Array* arr);
int is_empty(Array* arr);

void fill_random(Array* arr, unsigned long count);
void remove_even_numbers(Array* arr);
unsigned int count_ends_with_one(Array* arr);
void print_array(Array* arr);

#endif
