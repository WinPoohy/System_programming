# include <stdio.h>
int main() {
    int num = 568093600;
    char sum = 0;
    for (; num; num /= 10) sum += num % 10;
    printf("%d\n", sum);
    return 0;
}
