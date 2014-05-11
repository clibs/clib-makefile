
#ifndef FOO_H
#define FOO_H 1

#if __GNUC__ >= 4
# define FOO_EXTERN __attribute__((visibility("default")))
#else
# define FOO_EXTERN
#endif

FOO_EXTERN void
foo ();

#endif
