### Might need customized
# Final executable/program name
EXECUTABLE_NAME ?= main
# Compiler
CC ?= gcc
# C/CPP standard flag
C_STANDARD ?= -ansi
# C/CPP Compile Flags
PROJECT_CC_FLAGS ?= -pedantic -Wall
# Where source code is located (Probably don't change me)
SOURCE_DIRS ?= .

### Don't touch me
# Arg aggregations
PARGS ?=
CC_FLAGS ?= $(INC_FLAGS) $(C_STANDARD) $(PROJECT_CC_FLAGS)
SOURCE_FILES := $(shell find $(SOURCE_DIRS) -name *.cpp -or -name *.c -or -name *.s)
BUILD_OBJECTS := $(addsuffix .o,$(basename $(SOURCE_FILES)))
BUILD_DEPENDENCIES := $(BUILD_OBJECTS:.o=.d)

INC_DIRS := $(shell find $(SOURCE_DIRS) -type d)
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

# alias: all -> standard build
.PHONY: all
all:$(EXECUTABLE_NAME)

# Standard build
.PHONY: $(EXECUTABLE_NAME)
$(EXECUTABLE_NAME): $(BUILD_OBJECTS)
	$(CC) $(LDFLAGS) $(BUILD_OBJECTS) $(LOADLIBES) $(LDLIBS) -o $(EXECUTABLE_NAME)

# Enable all debug symbols
.PHONY: debug
debug:$(BUILD_OBJECTS)
	$(CC) $(LDFLAGS) $(BUILD_OBJECTS) $(LOADLIBES) $(LDLIBS) -ggdb -o $(EXECUTABLE_NAME)


# Run through valgrind to check for mem leaks
# Pass PARGS=$args on make command to pass for usage
.PHONY: memory
memory:debug
	valgrind "$(shell pwd)/$(EXECUTABLE_NAME)" "$(PARGS)"

# Production build, debug symbols stripped
.PHONY: prod
prod:$(EXECUTABLE_NAME)
	$(shell strip $(EXECUTABLE_NAME))

# Checks format
.PHONY: check-format
check-format:
	@for src in $(SOURCE_FILES) ; do \
		var=`clang-format "$(SOURCE_DIRS)/$$src " | diff "$(SOURCE_DIRS)/$$src" - | wc -l` ; \
		if [ $$var -ne 0 ] ; then \
			echo "$$src does not respect the coding style (diff: $$var lines)" ; \
			exit 1 ; \
		fi ; \
	done
	@echo "Style check passed"

# Auto formats based on checks
.PHONY: check-format
auto-format:
	@for src in $(SOURCE_FILES) ; do \
		echo "Formatting $$src..." ; \
		clang-format -i "$(SOURCE_DIRS)/$$src" ; \
	done
	@echo "Done"

# Checks style
.PHONY: check-format
check-style:
	@for src in $(SOURCE_FILES) ; do \
		echo "Formatting $$src..." ; \
		clang-tidy -checks=* \
			-header-filter=.* \
		    -config="{CheckOptions: [ \
		    { key: readability-identifier-naming.NamespaceCase, value: lower_case },\
		    { key: readability-identifier-naming.ClassCase, value: CamelCase  },\
		    { key: readability-identifier-naming.StructCase, value: CamelCase  },\
		    { key: readability-identifier-naming.FunctionCase, value: camelBack },\
		    { key: readability-identifier-naming.VariableCase, value: lower_case },\
		    { key: readability-identifier-naming.GlobalConstantCase, value: UPPER_CASE }\
		    ]}" "$(SOURCE_DIRS)/$$src" -- ; \
	done
	@echo "Done"


# Clean all the things
.PHONY: clean
clean:
	$(RM) $(EXECUTABLE_NAME) $(BUILD_OBJECTS) $(BUILD_DEPENDENCIES)

-include $(BUILD_DEPENDENCIES)

