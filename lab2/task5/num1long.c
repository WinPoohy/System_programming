# include <stdio.h>

int main() {
    long long num =3363522457;
    int sum = 0;

    while (num > 0) {
        sum += num % 10;
        num /= 10;
    }

    printf("%d\n", sum);
    return 0;
}
