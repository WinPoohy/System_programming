// queue.h
#ifndef QUEUE_H
#define QUEUE_H

typedef struct Node {
    unsigned long data;
    struct Node* next;
} Node;

typedef struct {
    Node* front;
    Node* rear;
    unsigned long size;
} Queue;

Queue* create_queue();
void free_queue(Queue* q);
void enqueue(Queue* q, unsigned long value);
unsigned long dequeue(Queue* q);
int is_empty(Queue* q);

void fill_random(Queue* q, unsigned long count);
void remove_even_numbers(Queue* q);
unsigned int count_primes(Queue* q);
unsigned int count_even_numbers(Queue* q);
void print_queue(Queue* q);

unsigned int ranint();
int is_prime(unsigned long n);

#endif
