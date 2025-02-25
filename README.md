# tmp
Scratch Repo
C interop without headers

```
git clone --depth=1 https://github.com/antono2/tmp
cd tmp
gcc -c -fPIC include/array.c
gcc -fPIC -shared array.o
v run .
```
