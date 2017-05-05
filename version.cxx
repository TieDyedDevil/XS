/* version.cxx -- version number */
#include "xs.hxx"
#include "git_date.hxx"
#include "git_hash.hxx"
#include "git_url.hxx"
static const char id[] = PACKAGE_STRING " (git: " GIT_DATE "; " GIT_HASH " @ " GIT_URL ")";
const char * const version = id;
