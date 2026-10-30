/* refstep.c -- independent bit-serial reference for elementary
 * cellular automata, used only by tests/run_rulec.sh to check the
 * rule compiler's output against direct simulation.
 *
 * Usage: refstep RULE WIDTH STEPS BOUNDARY INIT
 * Prints STEPS+1 rows (generation 0..STEPS), one bit per cell.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
    if (argc != 6) { fprintf(stderr, "usage: refstep RULE WIDTH STEPS BOUNDARY INIT\n"); return 2; }
    int rule = atoi(argv[1]), width = atoi(argv[2]), steps = atoi(argv[3]);
    int wrap = !strcmp(argv[4], "wrap");
    const char *init = argv[5];
    if ((int)strlen(init) != width) { fprintf(stderr, "bad init\n"); return 2; }
    int *cur = malloc(sizeof(int) * (size_t)width);
    int *nxt = malloc(sizeof(int) * (size_t)width);
    if (!cur || !nxt) return 2;
    for (int i = 0; i < width; i++) cur[i] = init[i] == '1';
    for (int t = 0; t <= steps; t++) {
        for (int i = 0; i < width; i++) putchar(cur[i] ? '1' : '0');
        putchar('\n');
        for (int i = 0; i < width; i++) {
            int l, c = cur[i], r;
            if (wrap) {
                l = cur[(i - 1 + width) % width];
                r = cur[(i + 1) % width];
            } else {
                l = i > 0 ? cur[i - 1] : 0;
                r = i < width - 1 ? cur[i + 1] : 0;
            }
            nxt[i] = (rule >> ((l << 2) | (c << 1) | r)) & 1;
        }
        int *tmp = cur; cur = nxt; nxt = tmp;
    }
    free(cur); free(nxt);
    return 0;
}
