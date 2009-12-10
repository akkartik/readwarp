#include<stdio.h>
#include<string>
using std::string;

extern "C" {
char* keywords(char*);
}

int main(int argc, char* argv[]) {
  char buf[8192];
  for(;;) {
      if (scanf("%s", buf) == EOF) break;
      string s("urls/");
      s += buf;
      s += ".clean";
      char* s2 = const_cast<char*>(s.c_str());
      printf("%s\n", keywords(s2));
  }
}
