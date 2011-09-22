#include <stdio.h>
#include <stdlib.h>

#include <ruby.h>

#if PYGMENTS_PYTHON_VERSION == 24
#include <python2.4/Python.h>
#elif PYGMENTS_PYTHON_VERSION == 25
#include <python2.5/Python.h>
#elif PYGMENTS_PYTHON_VERSION == 26
#include <python2.6/Python.h>
#elif PYGMENTS_PYTHON_VERSION == 27
#include <python2.7/Python.h>
#else
#error Unknown python version
#endif

#ifdef RUBY_VM
#include <ruby/st.h>
#include <ruby/encoding.h>
#else
#include <st.h>
#endif

#ifndef RSTRING_PTR
#define RSTRING_PTR(str) RSTRING(str)->ptr
#endif
#ifndef RSTRING_LEN
#define RSTRING_LEN(str) RSTRING(str)->len
#endif

static VALUE mPygments, mPygmentsC;
static PyObject
  /* modules */
  *pygments,
  *pygments_lexers,
  *pygments_formatters,
  *pygments_styles,
  *pygments_filters,

  /* lexer methods */
  *guess_lexer,
  *guess_lexer_for_filename,
  *get_lexer_for_mimetype,
  *get_lexer_for_filename,
  *get_lexer_by_name,
  *get_all_lexers,

  /* formatter methods */
  *get_formatter_by_name,
  *get_all_formatters,

  /* highlighter methods */
  *highlight,

  /* style methods */
  *get_all_styles,

  /* filter methods */
  *get_all_filters;

static int
each_hash_i(VALUE key, VALUE val, VALUE arg)
{
  Check_Type(key, T_SYMBOL);

  PyObject *py = (PyObject*) arg, *py_val = NULL;
  switch (TYPE(val)) {
    case T_NIL:
      return ST_CONTINUE;
      break;

    case T_FALSE:
      py_val = Py_False;
      break;

    case T_TRUE:
      py_val = Py_True;
      break;

    case T_STRING:
      py_val = PyString_FromString(RSTRING_PTR(val));
      break;

    default:
      Check_Type(val, T_STRING);
  }

  PyDict_SetItemString(py, rb_id2name(SYM2ID(key)), py_val);

  return ST_CONTINUE;
}

static PyObject*
rb_to_py(VALUE rb)
{
  PyObject *py = NULL;

  switch (TYPE(rb)) {
    case T_HASH:
      py = PyDict_New();
      rb_hash_foreach(rb, each_hash_i, (VALUE)py);
      break;
  }

  return py;
}

static VALUE
py_to_rb(PyObject *py)
{
  VALUE rb = Qnil;
  Py_ssize_t len, i;

  if (py) {
    if (PyIter_Check(py)) {
      PyObject *item;
      rb = rb_ary_new();

      while ((item = PyIter_Next(py))) {
        rb_ary_push(rb, py_to_rb(item));
        Py_DECREF(item);
      }

    } else if (PyString_Check(py)) {
      char *data;

      if (PyString_AsStringAndSize(py, &data, &len) == 0) {
        rb = rb_str_new(data, len);
      }

    } else if (PyTuple_Check(py)) {
      len = PyTuple_Size(py);

      PyObject *item;
      rb = rb_ary_new();

      for (i=0; i<len; i++) {
        item = PyTuple_GetItem(py, i);
        rb_ary_push(rb, py_to_rb(item));
      }

    } else if (PyList_Check(py)) {
      len = PyList_Size(py);

      PyObject *item;
      rb = rb_ary_new();

      for (i=0; i<len; i++) {
        item = PyList_GetItem(py, i);
        rb_ary_push(rb, py_to_rb(item));
      }

    } else if (PyDict_Check(py)) {
      PyObject *key, *val;
      Py_ssize_t pos = 0;

      rb = rb_hash_new();

      while (PyDict_Next(py, &pos, &key, &val)) {
        rb_hash_aset(rb, py_to_rb(key), py_to_rb(val));
      }
    }
  }

  return rb;
}

static PyObject*
pygments__lexer_for(VALUE code, VALUE options)
{
  VALUE filename, mimetype, lexer;
  PyObject *ret = NULL, *args = NULL, *kwargs = NULL;

  if (RTEST(code))
    Check_Type(code, T_STRING);

  if (RTEST(options)) {
    Check_Type(options, T_HASH);

    VALUE kw = rb_hash_aref(options, ID2SYM(rb_intern("options")));
    if (RTEST(kw)) {
      Check_Type(kw, T_HASH);
      kwargs = rb_to_py(kw);
    }

    lexer = rb_hash_aref(options, ID2SYM(rb_intern("lexer")));
    filename = rb_hash_aref(options, ID2SYM(rb_intern("filename")));
    mimetype = rb_hash_aref(options, ID2SYM(rb_intern("mimetype")));

    if (RTEST(lexer)) {
      Check_Type(lexer, T_STRING);
      args = Py_BuildValue("(s)", RSTRING_PTR(lexer));
      ret = PyObject_Call(get_lexer_by_name, args, kwargs);

    } else if (RTEST(mimetype)) {
      Check_Type(mimetype, T_STRING);
      args = Py_BuildValue("(s)", RSTRING_PTR(mimetype));
      ret = PyObject_Call(get_lexer_for_mimetype, args, kwargs);

    } else if (RTEST(filename)) {
      Check_Type(filename, T_STRING);

      if (RTEST(code)) {
        args = Py_BuildValue("(ss)", RSTRING_PTR(filename), RSTRING_PTR(code));
        ret = PyObject_Call(guess_lexer_for_filename, args, kwargs);
      } else {
        args = Py_BuildValue("(s)", RSTRING_PTR(filename));
        ret = PyObject_Call(get_lexer_for_filename, args, kwargs);
      }
    }
  }

  if (ret == NULL && RTEST(code)) {
    args = Py_BuildValue("(s)", RSTRING_PTR(code));
    ret = PyObject_Call(guess_lexer, args, kwargs);
  }

  Py_XDECREF(args);
  Py_XDECREF(kwargs);
  PyErr_Clear();
  return ret;
}

static VALUE
rb_pygments_lexer_name_for(int argc, VALUE *argv, VALUE self)
{
  VALUE code = Qnil, options = Qnil;
  VALUE name = Qnil;
  PyObject *lexer = NULL, *aliases = NULL;

  int found = rb_scan_args(argc, argv, "11", &code, &options);

  if (found > 0) {
    if (found == 1 && TYPE(code) == T_HASH) {
      options = code;
      code = Qnil;
    }

    lexer = pygments__lexer_for(code, options);

    if (lexer) {
      aliases = PyObject_GetAttrString(lexer, "aliases");
      if (aliases && PyList_Size(aliases) > 0) {
        PyObject *alias = PyList_GetItem(aliases, 0);
        name = rb_str_new2(PyString_AsString(alias));
      }
    }
  }

  Py_XDECREF(aliases);
  Py_XDECREF(lexer);
  PyErr_Clear();
  return name;
}

static VALUE
rb_pygments_css(int argc, VALUE *argv, VALUE self)
{
  VALUE css = Qnil, prefix = Qnil, options = Qnil;
  PyObject *args = NULL, *kwargs = NULL, *formatter = NULL;
  int found = rb_scan_args(argc, argv, "02", &prefix, &options);

  if (found == 1 && TYPE(prefix) == T_HASH) {
    options = prefix;
    prefix = Qnil;
  }

  if (RTEST(prefix))
    Check_Type(prefix, T_STRING);

  if (RTEST(options)) {
    Check_Type(options, T_HASH);
    kwargs = rb_to_py(options);
  }

  args = Py_BuildValue("(s)", "html");
  formatter = PyObject_Call(get_formatter_by_name, args, kwargs);
  if (formatter) {
    PyObject *styles = PyObject_CallMethod(formatter, "get_style_defs", "(s)", RTEST(prefix) ? RSTRING_PTR(prefix) : "");
    if (styles) {
      css = rb_str_new2(PyString_AsString(styles));
    }
    Py_XDECREF(styles);
  }

  Py_XDECREF(args);
  Py_XDECREF(kwargs);
  Py_XDECREF(formatter);
  PyErr_Clear();

  return css;
}

static VALUE
rb_pygments_highlight(int argc, VALUE *argv, VALUE self)
{
  PyObject *args = NULL, *kwargs = NULL, *lexer = NULL, *formatter = NULL;
  VALUE code = Qnil, options = Qnil, ret = Qnil, format = Qnil;
  rb_scan_args(argc, argv, "11", &code, &options);

  if (RTEST(options)) {
    format = rb_hash_aref(options, ID2SYM(rb_intern("formatter")));
    if (RTEST(format))
      Check_Type(format, T_STRING);

    VALUE kw = rb_hash_aref(options, ID2SYM(rb_intern("options")));
    if (RTEST(kw)) {
      Check_Type(kw, T_HASH);
      kwargs = rb_to_py(kw);
    }
  }

  lexer = pygments__lexer_for(code, options);

  if (lexer) {
    args = Py_BuildValue("(s)", RTEST(format) ? RSTRING_PTR(format) : "html");
    formatter = PyObject_Call(get_formatter_by_name, args, kwargs);
    Py_XDECREF(args);
    args = NULL;

    if (formatter) {
      PyObject *input = NULL, *output = NULL;

      input = PyUnicode_FromStringAndSize(RSTRING_PTR(code), RSTRING_LEN(code));
      if (input) {
        output = PyObject_CallFunction(highlight, "(OOO)", input, lexer, formatter);

        if (output) {
          PyObject *string = PyUnicode_AsEncodedString(output, "utf-8", "strict");
          if (string) {
            Py_ssize_t len;
            char *data;

            if (PyString_AsStringAndSize(string, &data, &len) == 0) {
              ret = rb_str_new(data, len);
            }
          }
          Py_XDECREF(string);
        }
      }

      Py_XDECREF(output);
      Py_XDECREF(input);
    }
  }

  Py_XDECREF(args);
  Py_XDECREF(kwargs);
  Py_XDECREF(lexer);
  PyErr_Clear();

#ifdef RUBY_VM
  if (RTEST(ret))
    rb_funcall(ret, rb_intern("force_encoding"), 1, rb_str_new2("utf-8"));
#endif

  return ret;
}

static VALUE
rb_pygments_styles(int argc, VALUE *argv, VALUE self)
{
  PyObject *styles = PyObject_CallFunction(get_all_styles, "");
  VALUE ret = py_to_rb(styles);
  Py_XDECREF(styles);
  PyErr_Clear();
  return ret;
}

static VALUE
rb_pygments_filters(int argc, VALUE *argv, VALUE self)
{
  PyObject *filters = PyObject_CallFunction(get_all_filters, "");
  VALUE ret = py_to_rb(filters);
  Py_XDECREF(filters);
  PyErr_Clear();
  return ret;
}

static VALUE
rb_pygments_lexers(int argc, VALUE *argv, VALUE self)
{
  PyObject *lexers = PyObject_CallFunction(get_all_lexers, "");
  VALUE ret = py_to_rb(lexers);
  Py_XDECREF(lexers);
  PyErr_Clear();
  return ret;
}

static VALUE
rb_pygments_formatters(int argc, VALUE *argv, VALUE self)
{
  PyObject *formatters = PyObject_CallFunction(get_all_formatters, "");
  PyObject *item;
  VALUE ret = rb_ary_new();

  while ((item = PyIter_Next(formatters))) {
    VALUE curr = rb_ary_new();
    rb_ary_push(ret, curr);

    rb_ary_push(curr, py_to_rb(PyObject_GetAttrString(item, "__name__")));
    rb_ary_push(curr, py_to_rb(PyObject_GetAttrString(item, "name")));
    rb_ary_push(curr, py_to_rb(PyObject_GetAttrString(item, "aliases")));

    Py_DECREF(item);
  }

  Py_XDECREF(formatters);
  PyErr_Clear();
  return ret;
}

#define ENSURE(var, expr) do{ \
  if ((var = (expr)) == NULL) { \
    rb_raise(rb_eRuntimeError, "unable to lookup " # var); \
  } \
} while(0)

void
Init_pygments_ext()
{
  { /* python stuff */
    Py_Initialize();

    /* modules */
    ENSURE(pygments, PyImport_ImportModule("pygments"));
    ENSURE(pygments_lexers, PyImport_ImportModule("pygments.lexers"));
    ENSURE(pygments_formatters, PyImport_ImportModule("pygments.formatters"));
    ENSURE(pygments_styles, PyImport_ImportModule("pygments.styles"));
    ENSURE(pygments_filters, PyImport_ImportModule("pygments.filters"));

    /* lexer methods */
    ENSURE(guess_lexer, PyObject_GetAttrString(pygments_lexers, "guess_lexer"));
    ENSURE(guess_lexer_for_filename, PyObject_GetAttrString(pygments_lexers, "guess_lexer_for_filename"));
    ENSURE(get_lexer_for_filename, PyObject_GetAttrString(pygments_lexers, "get_lexer_for_filename"));
    ENSURE(get_lexer_for_mimetype, PyObject_GetAttrString(pygments_lexers, "get_lexer_for_mimetype"));
    ENSURE(get_lexer_by_name, PyObject_GetAttrString(pygments_lexers, "get_lexer_by_name"));
    ENSURE(get_all_lexers, PyObject_GetAttrString(pygments_lexers, "get_all_lexers"));

    /* formatter methods */
    ENSURE(get_formatter_by_name, PyObject_GetAttrString(pygments_formatters, "get_formatter_by_name"));
    ENSURE(get_all_formatters, PyObject_GetAttrString(pygments_formatters, "get_all_formatters"));

    /* highlighter methods */
    ENSURE(highlight, PyObject_GetAttrString(pygments, "highlight"));

    /* style methods */
    ENSURE(get_all_styles, PyObject_GetAttrString(pygments_styles, "get_all_styles"));

    /* filter methods */
    ENSURE(get_all_filters, PyObject_GetAttrString(pygments_filters, "get_all_filters"));
  }

  { /* ruby stuff */
    mPygments = rb_define_module("Pygments");
    mPygmentsC = rb_define_module_under(mPygments, "C");
    rb_define_method(mPygmentsC, "lexer_name_for", rb_pygments_lexer_name_for, -1);
    rb_define_method(mPygmentsC, "css", rb_pygments_css, -1);
    rb_define_method(mPygmentsC, "_highlight", rb_pygments_highlight, -1);
    rb_define_method(mPygmentsC, "styles", rb_pygments_styles, 0);
    rb_define_method(mPygmentsC, "filters", rb_pygments_filters, 0);
    rb_define_method(mPygmentsC, "_lexers", rb_pygments_lexers, 0);
    rb_define_method(mPygmentsC, "_formatters", rb_pygments_formatters, 0);
  }
}
