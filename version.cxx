/* version.c -- version number */
#include "xs.hxx"
static const char id[] = "@(#)xs version 1.1";
const char * const version = id + (sizeof "@(#)" - 1);
