clib-makefile
=============

Interactively generate a `Makefile' for your C lib project with clibs in mind

## install

With [clib](https://github.com/clibs/clib):

```sh
$ clib install jwerle/clib-makefile
```

From source:

```sh
$ git clone git@github.com:jwerle/clib-makefile.git /tmp/clib-makefile
$ cd /tmp/clib-makefile
$ make install
```

## usage

Simply invoke `clib makefile` and you wil be prompted with a series
of questions about the generation of your `Makefile`. Most options
have defaults which can be defined with environment variables.

```sh
$ clib makefile
clib-makefile(1) v0.0.1
------------------------
Detected OS = 'Darwin'

Enter `Makefile' file name (Makefile): ~/repos/project/Makefile
Enter `CC' compiler (cc): gcc
Enter valgrind program (valgrind):
Enter sources (src/*.c):

...
```

You can skip the prompt process and use the defaults by making use
of the `-d` or `--default` flags.

```sh
$ clib makefile -d
clib-makefile(1) v0.0.1
------------------------
Detected OS = 'Darwin'

Enter `Makefile' file name (Makefile): ~/repos/libfoo/Makefile
`Makefile' already exists. Overwrite? (no): y
Use defaults? (no): y

+ `/Users/jwerle/repos/libfoo/Makefile'
```

You can force the answer `yes` on all prompts that require it
with the `-y` or `--yes` option.

```sh
$ clib makefile -d -y
clib-makefile(1) v0.0.1
------------------------
Detected OS = 'Darwin'

Enter `Makefile' file name (Makefile):

+ `/Users/jwerle/tmp/Makefile'
```

## license

MIT

