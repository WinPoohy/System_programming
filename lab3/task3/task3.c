#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char* argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Использование: %s a b c\n", argv[0]);
        fprintf(stderr, "Пример: %s 10 5 2\n", argv[0]);
        return 1;
    }

    double a = atof(argv[1]);
    double b = atof(argv[2]);
    double c = atof(argv[3]);

    if (c == 0) {
        fprintf(stderr, "Ошибка: деление на ноль!\n");
        return 1;
    }

    double result = ((((a - c) * b) / c) * a);

    printf("Выражение: ((((a-c)*b)/c)*a)\n");
    printf("Результат: %.2f\n", result);

    return 0;
}
