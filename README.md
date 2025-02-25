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
The idea here is to let the user decide which library file to use.
PATH_TO_LIBDIR is an environment variable, which is assumed to always be set on the users machine.
At a later point the user will also be able to use -d paramters to select groups of C functions to look up or not.
