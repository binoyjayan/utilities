#include<stdio.h>
#include<stdatomic.h>
#include<stdlib.h>

#include "atomic_stack.h"

void atomic_stack_init(_Atomic atomic_stack_t *stack) {
    atomic_stack_t temp = {0, NULL};
    atomic_store(stack, temp);
}

// the push function
void atomic_push(_Atomic atomic_stack_t *lfstack, int value)
{
    atomic_stack_t next;
    // here we need a local copy of lfstack, however, lfstack is a pointer
    // we could not get the content from a struct pointer atomically by assignment
    // C11 provides us a function for us to atomically get the content from the location that
    // a atomic type pointer points to.
    atomic_stack_t orig = atomic_load(lfstack);
    Node *node = malloc(sizeof(Node));
    node->data = value;
    do{
        node->next = orig.head;
        next.head = node;
        next.tag = orig.tag + 1; //increase the "tag"
    }while(!atomic_compare_exchange_weak(lfstack, &orig,next));
}

// pop function
int atomic_pop(_Atomic atomic_stack_t *lfstack) {
    atomic_stack_t next, orig = atomic_load(lfstack);
    do {
       if(orig.head == NULL) {
            return -1; // empty
       }
       next.head = orig.head->next; //set the head to the next node
       next.tag = orig.tag+1; //increase the "tag"
    } while(!atomic_compare_exchange_weak(lfstack, &orig,next)); //if the head of stack is not changed, update the stack

    printf("poping value %d\n",orig.head->data);
    free(orig.head);
    return 0;
}