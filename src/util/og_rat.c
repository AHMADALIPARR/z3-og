#include "og_rat.h"
static __int128 igcd128(__int128 a, __int128 b){
    if (a < 0) a = -a;
    if (b < 0) b = -b;
    while (b) { __int128 t = a % b; a = b; b = t; }
    return a ? a : 1;
}
static rat rat_from128(__int128 n, __int128 d){
    if (d < 0) { n = -n; d = -d; }
    __int128 g = igcd128(n, d);
    n /= g; d /= g;
    rat r = { (int64_t)n, (int64_t)d };
    return r;
}
rat rat_make(int64_t num, int64_t den){ return rat_from128(num, den); }
rat rat_int(int64_t v){ rat r = { v, 1 }; return r; }
rat rat_add(rat a, rat b){
    return rat_from128((__int128)a.num * b.den + (__int128)b.num * a.den,
                       (__int128)a.den * b.den);
}
rat rat_sub(rat a, rat b){ return rat_add(a, rat_neg(b)); }
rat rat_mul(rat a, rat b){
    return rat_from128((__int128)a.num * b.num, (__int128)a.den * b.den);
}
rat rat_neg(rat a){ rat r = { -a.num, a.den }; return r; }
int rat_cmp(rat a, rat b){
    __int128 l = (__int128)a.num * b.den, r = (__int128)b.num * a.den;
    return l < r ? -1 : (l > r ? 1 : 0);
}
bool rat_is_int(rat a){ return a.den == 1; }
int64_t rat_floor(rat a){
    if (a.num >= 0) return a.num / a.den;
    return -((-a.num + a.den - 1) / a.den);
}
int64_t rat_ceil(rat a){
    if (a.num >= 0) return (a.num + a.den - 1) / a.den;
    return -((-a.num) / a.den);
}
