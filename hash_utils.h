// Prolog. {{{
#ifndef __HASH_UTILS_H__
#define __HASH_UTILS_H__

#include <ext/hash_set>
#include <ext/hash_map>
using __gnu_cxx::hash_set ;
using __gnu_cxx::hash_map ;
using __gnu_cxx::hash_multimap ;
using __gnu_cxx::hash ;

#include <string>
#include <set>
#include <map>
#include <list>

using std::string ;
using std::set ;
using std::map ;
using std::multimap ;
using std::list ;

#ifndef FIND
    #define FIND(C, e) (C.find(e) != C.end())
#endif
// }}}

// Hash* {{{
template <class T>
class typeCastHash {
    hash <unsigned long> hsh ;
    public:
    size_t operator() (const T& b) const {
        size_t h = hsh ((unsigned long) b) ;
        return h ;
    }
} ;

template <class Key>
class HashSet :public hash_set<Key, typeCastHash<Key> > {} ;
template <class Key, class Data>
class HashMap :public hash_map<Key, Data, typeCastHash<Key> > {} ;
template <class Key, class Data>
class HashMultimap :public hash_multimap<Key, Data, typeCastHash<Key> > {} ;
// }}}

// Addr* {{{
// From http://burtleburtle.net/bob/hash/hashfaq.html
// len = 0
template <class T>
class AddrHash {
    public:
    size_t operator () (const T& b) const {
        size_t h = 0 ;

        h += (unsigned long) b ;
        h += (h<<10);
        h ^= (h>>6);

        h += (h<<3);
        h ^= (h>>11);
        h += (h<<15);

        return h ;
    }
} ;

template <class Key>
class AddrSet :public hash_set<Key, AddrHash<Key> > {} ;
template <class Key, class Data>
class AddrMap :public hash_map<Key, Data, AddrHash<Key> > {} ;
template <class Key, class Data>
class AddrMultimap :public hash_multimap<Key, Data, AddrHash<Key> > {} ;
// }}}

// OrderedHashSet: Ordered container with fast find. At cost of 2x storage. {{{
template<class T, class Hash = AddrHash<T> >
class OrderedHashSet {
public:
    void insert (const T& t) {
        if (!FIND(_hashTable, t)) {
            ++_size ;
            _list.push_back (t) ;
#ifdef ORDERED_HASH_SET__REALLY_USE_HASH_SET
            _hashTable.insert (t) ;
#else
            typename list<T>::iterator lp = _list.end() ;
            --lp ;
            _hashTable[t] = lp ;
#endif
        }
    }
    void push_front (const T& t) {
        if (!FIND(_hashTable, t)) {
            ++_size ;
            _list.push_front (t) ;
#ifdef ORDERED_HASH_SET__REALLY_USE_HASH_SET
            _hashTable.insert (t) ;
#else
            typename list<T>::iterator lp = _list.begin() ;
            _hashTable[t] = lp ;
#endif
        }
    }
    void push_back (const T& t) {
        insert (t) ;
    }
#ifndef ORDERED_HASH_SET__REALLY_USE_HASH_SET
    // LRU. Post-condition: front() == t.
    void push_front_or_update (const T& t) {
        if (FIND(_hashTable, t)) {
            _list.erase (_hashTable[t]) ;
            _hashTable.erase (t) ;
            --_size ;
        }

        push_front (t) ;
    }
#endif

    bool contains (const T& t) const {
        return _hashTable.find(t) != _hashTable.end() ;
    }

    bool empty () {
        return _list.empty () ;
    }

#ifdef ORDERED_HASH_SET__REALLY_USE_HASH_SET
    OrderedHashSet (hash_set<T, Hash>& h)
        :_hashTable(h),
        _list(h.begin(), h.end()),
        _size(h.size()) {}
#else
    OrderedHashSet ()
        :_size(0) {}
#endif

    typedef typename list<T>::iterator iterator ;
    typedef typename list<T>::const_iterator const_iterator ;
    typedef typename list<T>::reverse_iterator reverse_iterator ;
    iterator begin() {
        return _list.begin() ;
    }
    iterator end() {
        return _list.end() ;
    }
    reverse_iterator rbegin() {
        return _list.rbegin() ;
    }
    reverse_iterator rend() {
        return _list.rend() ;
    }

    T& front() {
        return _list.front() ;
    }
    T& back() {
        return _list.back() ;
    }

    const T& find(const T& t) const {
        return _hashTable.find(t)->first ;
    }

#ifndef ORDERED_HASH_SET__REALLY_USE_HASH_SET
    void erase (T& t) {
        if (FIND(_hashTable, t)) {
            _list.erase (_hashTable[t]) ;
            _hashTable.erase (t) ;
            --_size ;
        }
    }
#endif
    void erase (iterator& t) {
        _list.erase (t) ;
        _hashTable.erase (*t) ;
        --_size ;
    }
    void pop_front() {
        T& tmp = _list.front() ;
        _list.pop_front () ;
        _hashTable.erase (tmp) ;
        --_size ;
    }
    void pop_back() {
        T& tmp = _list.back () ;
        _list.pop_back () ;
        _hashTable.erase (tmp) ;
        --_size ;
    }

    size_t size () const {
        return _size ;
    }

private:
    // Invariant: _hashTable and _list always contain precisely the same
    // elements.
#ifdef ORDERED_HASH_SET__REALLY_USE_HASH_SET
    hash_set<T, Hash>& _hashTable ;
#else
    hash_map<T, typename list<T>::iterator, Hash> _hashTable ;
#endif
    list<T> _list ;
    size_t _size ;
} ; // }}}

// String-specific stuff. {{{
void subst (string& buf, const string& from, const string& to) ;

struct strEq {
    bool operator () (const string& s1, const string& s2) const ;
} ;

struct strLt {
    bool operator () (const string& s1, const string& s2) const ;
} ;

struct hashString {
    size_t operator () (const string& s) const ;
} ;

typedef set<string, strLt> SetString ;
typedef hash_set<string, hashString, strEq> HashSetString ;
template <class Data>
class MapString :public map<string, Data, strLt> {} ;
template <class Data>
class MultimapString
    :public multimap<string, Data, strLt> {} ;
template <class Data>
class HashMapString :public hash_map<string, Data, hashString, strEq> {} ;
template <class Data>
class HashMultimapString
    :public hash_multimap<string, Data, hashString, strEq> {} ;
#endif
// }}}
