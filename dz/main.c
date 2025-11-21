// main.c
#include <stdio.h>
#include <stdlib.h>
#include "array.h"

void flush_stdout() {
    fflush(stdout);
}

int main() {
    Array* array = create_array();
    if (!array) {
        printf("Ошибка: Не удалось создать массив\n");
        return 1;
    }

    unsigned long n;
    printf("Введите количество случайных элементов для генерации: ");
    scanf("%lu", &n);

    printf("\n1. Заполнение массива %lu случайными числами\n", n);
    flush_stdout();
    fill_random(array, n);
    printf("Массив: ");
    flush_stdout();
    print_array(array);

    printf("Всего элементов: %lu\n", array->size);
    printf("Чисел, оканчивающихся на 1: %u\n", count_ends_with_one(array));
    flush_stdout();

    printf("\n2. Добавление числа 999 в конец\n");
    flush_stdout();
    add_to_end(array, 999);
    printf("Массив после добавления: ");
    flush_stdout();
    print_array(array);

    printf("\n3. Удаление из начала: %lu\n", remove_from_start(array));
    flush_stdout();
    printf("Массив после удаления: ");
    flush_stdout();
    print_array(array);

    printf("\n4. Удаление четных чисел\n");
    flush_stdout();
    remove_even_numbers(array);
    printf("Массив после удаления четных чисел: ");
    flush_stdout();
    print_array(array);
    printf("Всего элементов: %lu\n", array->size);
    printf("Чисел, оканчивающихся на 1: %u\n", count_ends_with_one(array));
    flush_stdout();

    flush_stdout();
    free_array(array);

    return 0;
}
