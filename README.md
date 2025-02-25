# tmp
Scratch Repo
C interop without headers

```
git clone --depth=1 https://github.com/antono2/tmp
cd tmp
gcc -c -fPIC include/array.c
gcc -fPIC -shared array.o
PATH_TO_LIBDIR="$PWD" v run .
# Comment in one of the a.out strings.
# Either in v.mod or in main.v
PATH_TO_LIBDIR="$PWD" v run . 
```
