/* -*- Mode: C; c-basic-offset: 2; indent-tabs-mode: nil -*- */
/* vim: set filetype=c tabstop=2 shiftwidth=2 expandtab: */

/*
 * multival.d -- multiple values
 *
 * Copyright (c) 1984 Taiichi Yuasa and Masami Hagiya
 * Copyright (c) 1990 Giuseppe Attardi
 *
 * See file 'LICENSE' for the copyright details.
 *
 */

#include <ecl/ecl.h>
#include <ecl/internal.h>

@(defun values (&rest args)
  cl_object output;
@
  unlikely_if (narg > ECL_MULTIPLE_VALUES_LIMIT)
  FEerror("Too many values in VALUES",0);
  the_env->nvalues = narg;
  output = ECL_NIL;
  if (narg) {
    int i = 0;
    do { 
      the_env->values[i] = ecl_va_arg(args);
    } while (++i < narg);
    output = the_env->values[0];
  }
  return output;
@)

cl_object
cl_values_list(cl_object list)
{
  cl_env_ptr the_env = ecl_process_env();
  int i;
  the_env->values[0] = ECL_NIL;
  for (i = 0; !Null(list); list=ECL_CONS_CDR(list)) {
    unlikely_if (!LISTP(list))
      FEtype_error_list(list);
    unlikely_if (i == ECL_MULTIPLE_VALUES_LIMIT)
      FEerror("Too many values in VALUES-LIST",0);
    the_env->values[i++] = ECL_CONS_CAR(list);
  }
  the_env->nvalues = i;
  return the_env->values[0];
}
