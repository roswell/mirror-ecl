/*
    gfun.c -- Dispatch for generic functions.
*/
/*
    Copyright (c) 1990, Giuseppe Attardi.

    ECL is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    See file '../Copyright' for full details.
*/

#include "ecl.h"
#include "internal.h"

cl_object
si_set_funcallable(cl_object instance, cl_object flag)
{
	if (type_of(instance) != t_instance)
		FEwrong_type_argument(@'ext::instance', instance);
	instance->instance.isgf = !Null(flag);
	@(return instance)
}

cl_object
si_generic_function_p(cl_object instance)
{
	@(return (((type_of(instance) != t_instance) &&
		   (instance->instance.isgf))? Ct : Cnil))
}

/*
 * variation of gethash from hash.d, which takes an array of objects as key
 * It also assumes that entries are never removed except by clrhash.
 */

static struct ecl_hashtable_entry *
get_meth_hash(cl_object *keys, int argno, cl_object hashtable)
{
	int hsize;
	struct ecl_hashtable_entry *e, *htable;
	cl_object hkey, tlist;
	register cl_index i = 0;
	int k, n; /* k added by chou */
	bool b = 1;

	hsize = hashtable->hash.size;
	htable = hashtable->hash.data;
	for (n = 0; n < argno; n++)
	  i += (cl_index)keys[n] / 4; /* instead of:
				   i += hash_eql(keys[n]);
				   i += hash_eql(Cnil);
				 */
	for (i %= hsize, k = 0; k < hsize;  i = (i + 1) % hsize, k++) {
	  e = &htable[i];
	  hkey = e->key;
	  if (hkey == OBJNULL)
	    return(e);
	  for (n = 0, tlist = hkey; b && (n < argno);
	       n++, tlist = CDR(tlist))
	    b &= (keys[n] == CAR(tlist));
	  if (b)
	    return(&htable[i]);
	}
	internal_error("get_meth_hash");
}

static void
set_meth_hash(cl_object *keys, int argno, cl_object hashtable, cl_object value)
{
	struct ecl_hashtable_entry *e;
	cl_object keylist, *p;
	cl_index i;

	i = hashtable->hash.entries + 1;
	if (i > 512) {
		/* It does not make sense to let these hashes grow large */
		cl_clrhash(hashtable);
	} else if (i >= hashtable->hash.size ||
		   i >= (hashtable->hash.size * hashtable->hash.factor)) {
		ecl_extend_hashtable(hashtable);
	}
	keylist = Cnil;
	for (p = keys + argno; p > keys; p--) keylist = CONS(p[-1], keylist);
	e = get_meth_hash(keys, argno, hashtable);
	if (e->key == OBJNULL) {
		e->key = keylist;
		hashtable->hash.entries++;
	}
	e->value = value;
}

cl_object
compute_method(cl_narg narg, cl_object gf, cl_object *args)
{
	cl_object func;
	int i, spec_no;
	struct ecl_hashtable_entry *e;
	cl_object spec_how_list = GFUN_SPEC(gf);
	cl_object table = GFUN_HASH(gf);
#ifdef __GNUC__
	cl_object argtype[narg]; /* __GNUC__ */
#else
#define ARGTYPE_MAX 64
	cl_object argtype[ARGTYPE_MAX];
	if (narg > ARGTYPE_MAX)
	  FEerror("compute_method: Too many arguments, limited to ~A.", 1, MAKE_FIXNUM(ARGTYPE_MAX));
#endif

	for (spec_no = 0; spec_how_list != Cnil;) {
		cl_object spec_how = CAR(spec_how_list);
		cl_object spec_type = CAR(spec_how);
		int spec_position = fix(CDR(spec_how));
		if (spec_position >= narg)
			FEwrong_num_arguments(gf);
		argtype[spec_no++] =
			(ATOM(spec_type) ||
			 Null(memql(args[spec_position], spec_type))) ?
			cl_class_of(args[spec_position]) :
			args[spec_position];
		spec_how_list = CDR(spec_how_list);
	}

	e = get_meth_hash(argtype, spec_no, table);

	if (e->key == OBJNULL) {
		/* method not cached */
		cl_object methods, arglist;
		for (i = narg, arglist = Cnil; i-- > 0; ) {
			arglist = CONS(args[i], arglist);
		}
		methods = funcall(3, @'compute-applicable-methods', gf,
				  arglist);
		func = funcall(4, @'si::compute-effective-method', gf,
			       GFUN_COMB(gf), methods);
		/* update cache */
		set_meth_hash(argtype, spec_no, table, func);
	} else {
		/* method is already cached */
		func = e->value;
	}
	return func;
}

cl_object
si_set_compiled_function_name(cl_object fn, cl_object new_name)
{
	cl_type t = type_of(fn);

	if (t == t_cfun)
		@(return (fn->cfun.name = new_name))
	if (t == t_bytecodes)
		@(return (fn->bytecodes.name = new_name))
	FEerror("~S is not a compiled-function.", 1, fn);
}
