#include <stdio.h>
#include <pthread.h>

#include "atomic_stack.h"

void *push(void *arg) {
    _Atomic atomic_stack_t *top = (_Atomic atomic_stack_t *) arg;
    for(int i=0; i<100000; i++) {
        atomic_push(top, i);
        printf("push %d\n",i);
    }
    pthread_exit(NULL);
}

void *pop(void *arg) {
    _Atomic atomic_stack_t *top = (_Atomic atomic_stack_t *) arg;
    for(int i=0; i < 100000;) {
        int result;
        result = atomic_pop(top);
        if(result == -1)
            printf("the stack is empty\n");
        else {
            i++;
        }
    }
    pthread_exit(NULL);
}

int main() {
    _Atomic atomic_stack_t top;
    atomic_stack_init(&top);
    pthread_t tid[200];
    for(int i=0; i<100; i++)
        pthread_create(&tid[i], NULL, push, &top);
    for(int i=100; i<200; i++)
        pthread_create(&tid[i], NULL, pop, &top);
    for(int i=0; i<200; i++)
        pthread_join(tid[i],NULL);  
    return 0;
}