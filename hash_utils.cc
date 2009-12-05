#include "hash_utils.h"

using namespace std ;

bool strLt :: operator () (const string& s1, const string& s2) const {
    return s1 < s2 ;
}

bool strEq :: operator () (const string& s1, const string& s2) const {
    return s1 == s2 ;
}

size_t hashString :: operator () (const string& s) const {
    static hash<char*> h ;
    return h (s.c_str ()) ;
}

void subst (string& buf, const string& from, const string& to) {
    string::size_type pos = 0 ;
    while (pos < buf.length ()) {
        pos = buf.find (from, pos) ;

        if (pos < buf.length ()) {
            buf.erase (pos, from.length ()) ;
            buf.insert (pos, to) ;
        }
    }

    return ;
}
