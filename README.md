# tmp
Scratch Repo
@[keep_args_alive] example with void functions

```
git clone --depth=1 https://github.com/antono2/tmp
cd tmp
# build a.out
gcc -c -fPIC include/array.c
gcc -fPIC -shared array.o
# check if it runs
v run .
# comment in @[keep_args_alive] and run again
v run .

```
