#ifndef _ATOMICS_STACK_H_
#define _ATOMICS_STACK_H_

// the node type in the stack
typedef struct _Node {
    int data;
    struct _Node* next;
} Node;

// the stack
typedef struct _lfstack_t {
    int tag;
    Node *head;
} atomic_stack_t;

void atomic_stack_init(_Atomic atomic_stack_t *stack);
void atomic_push(_Atomic atomic_stack_t *lfstack, int value);
int atomic_pop(_Atomic atomic_stack_t *lfstack);

#endif // _ATOMICS_STACK_H_