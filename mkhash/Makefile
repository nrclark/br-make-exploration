HOWZA := fuck
my_dinkum := ass

CXXFLAGS ?= -O2 -std=c++17 -flto
CXXFLAGS += -Wall -Wextra -pedantic -Werror

mk_temp.so: mk_temp.cpp
	$(CXX) $(CXXFLAGS) -shared -fPIC -s -o $@ $<

-load mk_temp.so
$(info $(find_variables hello my dudes,HOW ARE,you))
all:
	@echo Temporary file: $(mk-temp tmpfile.,fuck,you)
