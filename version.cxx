/* version.cxx -- version number */
#include "xs.hxx"
#include "git_info.hxx"
static const char id[] = PACKAGE_STRING " (" GIT_INFO ")";
const char * const version = id;
