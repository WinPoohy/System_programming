// main.c
#include <stdio.h>
#include <stdlib.h>
#include "array.h"

void flush_stdout() {
    fflush(stdout);
}

int main() {
    printf("=== Демонстрация работы с массивом (FASM + mmap) ===\n");

    Array* array = create_array();
    if (!array) {
        printf("Ошибка: Не удалось выделить память (mmap failed)\n");
        return 1;
    }

    unsigned long n;
    printf("Введите количество элементов для генерации: ");
    if (scanf("%lu", &n) != 1) n = 5; // Дефолтное значение при ошибке ввода

    printf("\n1. Заполнение случайными числами (%lu шт.)\n", n);
    fill_random(array, n);
    printf("Массив: "); flush_stdout();
    print_array(array);

    printf("Всего элементов: %lu\n", array->size);
    printf("Чисел, оканчивающихся на 1: %u\n", count_ends_with_one(array));

    printf("\n2. Добавление числа 101 (для проверки окончания на 1)\n");
    add_to_end(array, 101);
    add_to_end(array, 42);
    printf("Массив: "); flush_stdout();
    print_array(array);
    printf("Чисел, оканчивающихся на 1: %u\n", count_ends_with_one(array));

    printf("\n3. Удаление из начала\n");
    unsigned long val = remove_from_start(array);
    printf("Удалено: %lu\n", val);
    printf("Массив: "); flush_stdout();
    print_array(array);

    printf("\n4. Удаление четных чисел\n");
    remove_even_numbers(array);
    printf("Массив (остались только нечетные): "); flush_stdout();
    print_array(array);

    printf("\nОсвобождение памяти...\n");
    free_array(array);
    printf("Готово.\n");

    return 0;
}
