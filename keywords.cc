#include<stdio.h>
#include<list>
#include<string>
#include<vector>
#include<math.h>
#include<string.h>
#include"hash_utils.h"

using std::list;
using std::string;
using std::vector;
using std::pair;

void initializations();

extern "C" {
char* stem(char*);
}

void p(char* m) {
  printf("%s", m); fflush(stdout);
}

int input_max = 1024*1024*30;
char* input = new char[input_max];
int input_count = 0;
void set_input(const char* x) {
  input_count = strlen(x);
  strncpy(input, x, input_count);
}
void reset_input() {
  memset(input, 0, input_max);
  input_count = 0;
}
int read_file(FILE* f) {
  if (input_count >= input_max) {
    printf("file too long %d >= %d\n", input_count, input_max);
    exit(255);
  }

  input[input_count++] = tolower(fgetc(f));
  return !feof(f);
}

bool m(string pat) {
  if (input_count <= 0) return pat == "";
  int len = pat.length();
  if (input_count < len) return false;
//?   printf("searching for %s %d %d\n", const_cast<char*>(pat.c_str()),
//?       input_count, input_max);
//?   fflush(stdout);

  int count = 0;
  int idx = 0;
  for (idx = input_count-len; idx < input_count; ++idx, ++count) {
    if (input[idx] != pat[count])
      return false;
  }

  return true;
}

static bool in_comment = false;
static bool in_script = false;
static bool in_style = false;
static bool in_tag = false;
// return true -> current_word contains word
bool next_lex() {
//?   printf("^\n"); fflush(stdout);
  if (in_comment && m("-->"))
    in_comment = false;
  else if (in_comment)
    ;

  else if (in_script && m("</script>"))
    in_script = false;
  else if (in_script)
    ;

  else if (in_style && m("</style>"))
    in_style = false;
  else if (in_style)
    ;

  else if (m("<script>") || m("<script "))
    in_tag=false, in_script=true;
  else if (m("<style>") || m("<style "))
    in_tag=false, in_style=true;
  else if (m("<!--"))
    in_tag=false, in_comment=true;
  else if (m(">"))
    in_tag=false;
  else if (m("<"))
    in_tag=true;

//?   printf("$\n"); fflush(stdout);
  return !(in_comment || in_script || in_style || in_tag);
}
void mock_lex(string s) {
  initializations();
  for (string::iterator cp = s.begin(); cp != s.end(); ++cp) {
    char c = *cp;
    input[input_count++] = tolower(c);
    next_lex();
  }
}

void replace_suffix(int idx, int cnt, char c) {
  input[idx] = c;
  memset(input+idx+1, 0, cnt+2);
  input_count = idx+1;
}

bool replace_entity() {
  if (!m(";")) return false;

  int idx = input_count-2, cnt=0;
  for (; idx >= 0; --idx,++cnt) {
    if (input[idx] == '&') break;
    if (input[idx] == '#') continue;
    if (input[idx] < '0' || input[idx] > 'z') return false;
    if (input[idx] > '9' && input[idx] < 'A') return false;
    if (input[idx] > 'Z' && input[idx] < 'a') return false;
  }
  if (cnt < 2 || cnt > 6) return false;

  char* s = new char[cnt+1];
  memset(s, 0, cnt+1);
  strncpy(s, input+idx+1, cnt);
  if (strcmp(s, "lquo") == 0 || strcmp(s, "rquo") == 0 || strcmp(s, "#8220") == 0 || strcmp(s, "#8221") == 0 || strcmp(s, "#39") == 0)
    replace_suffix(idx, cnt, '\'');
  else if (strcmp(s, "nbsp") == 0)
    replace_suffix(idx, cnt, ' ');
  else
    replace_suffix(idx, cnt, '"'); // Always a word boundary.

  delete[] s;
  return true;
}

const int NEVER_WORD = 0;
const int MAYBE_WORD = 1;
const int ALWAYS_WORD = 2;
int charclass(char c) {
  if (c == ',' || c == ';' || c == '"' || c == '!' || c == '[' || c == ']'
      || c == '(' || c == ')' || c == '|' || c == '\'' || c == '\0' || isspace(c))
    return NEVER_WORD;

  if (c == '.' || c == '=' || c == '-' || c == '=' || c == '/'
      || c == ':' || c == '&' || c == '?')
    return MAYBE_WORD;

  return ALWAYS_WORD;
}

vector<string> words;
void add_to_curr_word(char c) {
  words.back().push_back(c);
}
void start_new_word() {
  words.push_back("");
}

bool not_word(char c) {
  return charclass(c) == NEVER_WORD;
}

int state = 0;
bool next_word(char last, char curr, char next) {
  int newstate = charclass(curr);
  if (newstate == MAYBE_WORD) {
    if (not_word(last) || not_word(next) || next == 0)
      newstate = NEVER_WORD;
    else
      newstate = ALWAYS_WORD;
  }

  if (newstate == state && newstate == ALWAYS_WORD)
    add_to_curr_word(curr);

  if (newstate != state && !words.back().empty())
    start_new_word();

  if (newstate != state && newstate == ALWAYS_WORD)
    add_to_curr_word(curr);

  state = newstate;
  return false;
}



int tests_failed = 0;
void check(bool expr, const char* msg) {
  if (expr) return;

  printf("E %s\n", msg);
  ++tests_failed;
}

int tests() {
  check(m(""), "m returns true when input and pat are empty");
  check(!m("a"), "m returns false when input is empty but pat is not");

  set_input("ald flasdj flasdj fladj flajsdf <script");
  check(m("<script"), "m returns true when suffix matches");
  check(!m("<scripts"), "m returns true when suffix doesn't match");
  check(m("t"), "m returns true when suffix matches single-letter pat");

  mock_lex("lajd lfa lsdfj aldjf l <!-");
  check(in_tag, "detects open html tag");
  mock_lex("lajd lfa lsdfj aldjf l <!-- ");
  check(in_comment, "detects open html comment");
  mock_lex("lajd lfa lsdfj aldjf l <scrip");
  check(in_tag, "detects open html tag");
  mock_lex("lajd lfa lsdfj aldjf l <script ");
  check(in_script, "detects open html script");

  check(!replace_entity(), "no entity to replace");
  check(strcmp(input, "lajd lfa lsdfj aldjf l <script ") == 0, "no entities replaced");
  mock_lex("abcdef&lquo;");
  check(replace_entity(), "entity replaced");
  check(strcmp(input, "abcdef'") == 0, "&lquo; replaced with '");
  mock_lex("abcdef&;");
  replace_entity();
  mock_lex("abcdef&a;");
  replace_entity();
  mock_lex("abcdef&ab;");
  replace_entity();
  mock_lex("abcdef&a-b;");
  check(!replace_entity(), "no entities with non-alphanumeric chars");

  mock_lex("the dog jumped over the mat's fellow. meow.");
  state = charclass(input[0]);
  start_new_word();
  if (charclass(input[0]) == ALWAYS_WORD)
    add_to_curr_word(input[0]);
  for (int c = 1; c < input_count; ++c)
    next_word(input[c-1], input[c], input[c+1]);
//?   for (vector<string>::iterator wp = words.begin(); wp != words.end(); ++wp) {
//?     string word = *wp;
//?     printf("%d %s\n", word.size(), word.c_str());
//?   }
  check(words[0] == "the", "a0");
  check(words[1] == "dog", "a1");
  check(words[2] == "jumped", "a2");
  check(words[3] == "over", "a3");
  check(words[4] == "the", "a4");
  check(words[5] == "mat's", "a5");
  check(words[6] == "fellow", "a6");
  check(words[7] == "meow", "a7");

  return tests_failed;
}

char* realstem(string s) {
  char* ans = new char[s.size()+1];
  strncpy(ans, s.c_str(), s.size()+1);
  ans = stem(ans);
  return ans;
}

vector<int> deltas(string gram, vector<string> grams, float* avg) {
  int idx = 0;
  float first_idx = 0, last_idx = 0, num_idx = 0;
  int prev_idx = -1;
  vector<int> ans;
  for (vector<string>::iterator gp = grams.begin(); gp != grams.end(); ++gp,++idx) {
    string g = *gp;
    char* stemmed_g = realstem(g);
    if (gram == stemmed_g) {
      if (prev_idx == -1)
        first_idx = idx;
      else
        last_idx = idx;
      ++num_idx;

      if (prev_idx != -1)
        ans.push_back(idx-prev_idx);
      prev_idx = idx;
    }
    delete[] stemmed_g;
  }
  *avg = (last_idx-first_idx)/num_idx;
  return ans;
}

float sigma(vector<int> d, int avg) {
  float sum=0, sum2 = 0;
  for (vector<int>::iterator ip=d.begin(); ip!=d.end(); ++ip) {
    float n = *ip;
    n /= avg;

    sum+=n;
    sum2+=(n*n);
  }

  float n = d.size();
  sum /= n;
  sum2 /= n;
  return sum2 - sum*sum;
}

float adaptable_bound() {
  float variable = log10(words.size());
  int fixed = 5;
  return (variable < fixed) ? variable : fixed;
}

void sort_insert_by_sigma_delta(string gram, vector<string> grams, vector<pair<string, float> >& candidates) {
  if (gram.empty()) return;
  float avg = 0;
  vector<int> d = deltas(gram, grams, &avg);
//?   printf("considering: %s %d\n", gram.c_str(), d.size());
  if (d.size()+1 /*indices.size*/ < adaptable_bound()) return;

  float delta_sigma = sigma(d, avg);

  pair<string, float> currpair;
  currpair.first=gram;
  currpair.second=delta_sigma;
//?   printf("inserting %s %f\n", gram.c_str(), delta_sigma);
  vector<pair<string,float> >::iterator vp;
  for (vp=candidates.begin(); vp!=candidates.end(); ++vp) {
    pair<string, float> p = *vp;
    if (p.second < delta_sigma) {
      candidates.insert(vp, currpair);
      break;
    }
  }

  if (vp == candidates.end()) {
    candidates.push_back(currpair);
  }

  if (candidates.size() > 10) {
//?     p("before: ");
//?     for (vp=candidates.begin(); vp!=candidates.end(); ++vp)
//?       printf("%s(%f) ", vp->first.c_str(), vp->second);
//?     p("\n");
    if (candidates[9].second != candidates[10].second) {
      candidates.resize(10);
    }
//?     p("after: ");
//?     for (vp=candidates.begin(); vp!=candidates.end(); ++vp)
//?       printf("%s(%f) ", vp->first.c_str(), vp->second);
//?     p("\n");
  }
}

bool stop(string s) {
  static char curr[1024]; // XXX: security hole, not reentrant
  static HashSetString stop;
  if (stop.empty()) {
    FILE* f = fopen("stop_words", "r");
    while (!feof(f)) {
      fscanf(f, "%s", curr);
      stop.insert(curr);
    }
  }

  return stop.find(s) != stop.end();
}

void myfree(char* p) {
  if (p) delete[] p;
}

bool has_alpha(const char* s) {
  for (; *s; ++s) {
    if ((*s >= 'a' && *s <= 'z') || (*s >= 'A' && *s <= 'Z'))
      return true;
  }
  return false;
}

extern "C" {

char* keywords(char* filename) {
//?   printf("kwds: %s\n", filename);
  initializations();

//?   printf("AAA\n"); fflush(stdout);
  FILE* f = fopen(filename, "r");
  if (!f) {
    printf("no file");
    return const_cast<char*>("");
  }

//?   printf("BBB\n"); fflush(stdout);
  while (read_file(f)) {
    replace_entity();
  }
  fclose(f);

//?   printf("CCC\n"); fflush(stdout);
  // UGLY. Do I need a new buffer?
  char* input2 = new char[input_max];
  int cnt = 0;
  int correct_input_count = input_count;
  for (input_count = 1; input_count < correct_input_count; ++input_count) {
    if (!next_lex()) continue;
    if (m(">") && input2[cnt] != '"') {
      input2[cnt++] = '"';
      continue;
    }
    input2[cnt++] = input[input_count-1];
  }
//?   printf("DDD\n"); fflush(stdout);
  delete[] input;
  input = input2;

//?   printf("EEE\n"); fflush(stdout);
  state = charclass(input[0]);
  start_new_word();
  if (charclass(input[0]) == ALWAYS_WORD)
    add_to_curr_word(input[0]);
  for (int c = 1; c < input_count; ++c)
    next_word(input[c-1], input[c], input[c+1]);

//?   printf("FFF\n"); fflush(stdout);
  vector<pair<string, float> > candidates;
  HashSetString done;
  char* s = NULL;
  for (vector<string>::iterator sp = words.begin(); sp != words.end(); ++sp, myfree(s)) {
    s = realstem(*sp);
    if (done.find(s) != done.end()) continue;
    done.insert(s);

    if (stop(*sp) || stop(s)) continue;
    if (sp->size() <= 2) {
//?       printf("skipping %s\n", sp->c_str());
      continue;
    }
    if (!has_alpha(sp->c_str())) {
//?       printf("skipping2 %s\n", sp->c_str());
      continue;
    }
//?     printf("MMM\n"); fflush(stdout);

    sort_insert_by_sigma_delta(s, words, candidates);
//?     printf("ZZZ\n"); fflush(stdout);
  }

  int len=0;
  for (vector<pair<string,float> >::iterator wp = candidates.begin(); wp != candidates.end(); ++wp)
    len+=(wp->first.size()+1);
  len+=1;
  s = new char[len];

  int idx=0;
  for (vector<pair<string,float> >::iterator wp = candidates.begin(); wp != candidates.end(); ++wp) {
    string word = wp->first;
    if (idx+word.size()+1 >= len) break;
    if (idx != 0) idx+=sprintf(s+idx,",");
    idx += sprintf(s+idx, "%s", word.c_str());
  }

  return s;
}

}

void initializations() {
  reset_input();
  in_comment = in_script = in_style = in_tag = false;
  words.clear();
}

int main(int argc, char* argv[]) {
  if (argc == 0) return 1;
  if (strcmp(argv[1], "test") == 0)
    return tests();

  for(int i = 0; i < argc; ++i)
      printf("%s\n", keywords(argv[1]));

  return 0;
}
