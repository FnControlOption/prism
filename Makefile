ifeq ($(shell uname), Darwin)
SOEXT := dylib
else
SOEXT := so
endif

OPTFLAGS :=
CFLAGS :=

# Check for the presence of strncasecmp
ifeq ($(shell $(CC) -Iinclude -o /dev/null test/availability/strncasecmp.c 2>/dev/null && echo 1), 1)
CFLAGS := $(CFLAGS) -DHAVE_STRNCASECMP
endif

# Check for the presence of strnstr
ifeq ($(shell $(CC) -Iinclude -o /dev/null test/availability/strnstr.c 2>/dev/null && echo 1), 1)
CFLAGS := $(CFLAGS) -DHAVE_STRNSTR
endif

all: build/librubyparser.$(SOEXT) build/librubyparser.a

SOURCES := $(shell find src -name '*.c')
HEADERS := $(shell find src -name '*.h')
OBJECTS := $(patsubst src/%.c, build/%.o, $(SOURCES))
$(OBJECTS): build/%.o: src/%.c $(HEADERS) Makefile include/yarp/ast.h
	@mkdir -p $(dir $@)
	$(CC) $(OPTFLAGS) $(DEBUG_FLAGS) $(CFLAGS) -std=c99 -Wall -Werror -Wextra -Wpedantic -Wsign-conversion -fPIC -g -fvisibility=hidden -c -Iinclude -o $@ $<

build/librubyparser.$(SOEXT): $(OBJECTS)
	$(CC) -shared -o $@ $(OBJECTS)

build/librubyparser.a: $(OBJECTS)
	$(AR) rcs $@ $(OBJECTS)

build/profile: $(SOURCES) $(HEADERS) Makefile build include/yarp/ast.h bin/profile.c
	$(CC) $(CFLAGS) -O3 -std=c99 -Iinclude -o $@ $(SOURCES) bin/profile.c

build:
	mkdir -p build

include/yarp/ast.h: bin/templates/include/yarp/ast.h.erb
	rake $@

clean:
	rm -f \
		$(OBJECTS) \
		build/librubyparser.$(SOEXT) \
		build/librubyparser.a \
		ext/yarp/node.c \
		include/{ast.h,node.h} \
		java/org/yarp/{AbstractNodeVisitor.java,Loader.java,Nodes.java} \
		lib/yarp/{node,serialize}.rb \
		src/{node.c,prettyprint.c,serialize.c,token_type.c}

.PHONY: clean

all-no-debug: DEBUG_FLAGS := -DNDEBUG=1
all-no-debug: OPTFLAGS := -O3
all-no-debug: all
