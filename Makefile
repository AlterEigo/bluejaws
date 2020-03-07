
############################
#### PREAMBLE ##############
############################


# This makefile is fully optimized for a C project
# allowing you to do following things:
# - all:	assemble the entire project with the
#			eventual library
# - fclean:	remove your project's executable AND
#			object files
# - clean:  remove ONLY the object files, if any
# - re:		clean up and reassemble the project
#			from scratch
# - debug:	reassemble your entire project with
#			debug flag ('-g') and run GDB with custom
#			parameters sent to your program
#			(you can set custom arguments by modifying
#			the 'GDB_ARGV' variable)
# - __%_gc:	this one needs some extra explanation. When
#			you try to 'make __my_src_c' this makefile
#			will:
#				1.	compile all of your
#					source files into objects
#				2.	check for a file named 'my_src.c'
#					in your source folder
#				3.	check for a file named '__my_src.c'
#					in your tests folder
#				4.	recompile this precise source files
#					with coverage flags, without touching
#					the rest
#				5.	run the compiled unit test
#			So in the end, you compile your unit test
#			for the file 'my_src.c' if it's possible.
#			Therefore, if you want to use this ability,
#			you have to name your tests file as following:
#			'__%' where % is your original source file
#			name. Also, once unit tests launched, you can
#			analyze detailed coverage line by line
#			executing gcov (not gcovr)
# - __%:	same as previous, but without generating
#			coverage statistics
# - doc		this target calls doxygen inside of $(OXDOC_DIR)
# The only things that should be modified in this makefile
# are in the 'OPTIONS' and 'SOURCE FILES' sections.
# You have to enter all of your source files manually


############################
#### SUMMARY ###############
############################


# 1. Options
# 2. Source files
# 3. Compiler settings
# 4. Object files
# 5. Make recipies
# 6. File creation section
# 7. Pattern rules


############################
#### OPTIONS ###############
############################


TARGET_NAME			=	bluejaws
SOURCE_DIR			=	sources
OBJECT_DIR			=	objects
HEADER_DIR			=	include
TESTS_DIR			=	tests
OXDOC_DIR			=	docs
GDB_ARGV			=

vpath %.c $(SOURCE_DIR)


############################
#### SOURCE FILES ##########
############################


SOURCES_LIST		=	    	main.c
LIBRARY			=


############################
#### COMPILER SETTINGS #####
############################


CC			=	gcc
C_FLAGS			=	-W -Wall -Wextra -Werror \
				-I$(HEADER_DIR) \
				-Wno-switch \
				-Wno-unused-variable \
				-Wno-unused-parameter \
				-Wno-unused-but-set-variable \
				-Wno-unused-but-set-parameter \
				-Wno-unused-function \
				-Wno-deprecated-declarations \
				$(C_FLAGS_INPUT)
L_FLAGS			=	-lbluetooth $(L_FLAGS_INPUT)
COV_FLAGS		=	-fprofile-arcs -ftest-coverage
VALGRIND_FLAGS		=	--leak-check=full \
				--show-leak-kinds=all \
				--track-origins=yes \
				--verbose \
				--log-file=valgrind-out.txt


############################
#### OBJECT FILES (auto) ###
############################


OBJECTS			=	$(patsubst %.c, $(OBJECT_DIR)/%.o, $(SOURCES_LIST))
NON_M_OBJECTS		=	$(patsubst %main.o, , $(OBJECTS))


############################
#### RECIPE SECTION ########
############################


.PHONY: all directories re clean fclean library debug


all: directories $(LIBRARY) $(TARGET_NAME)


fullw:
	@make all C_FLAGS=-W\ -Wall\ -Wextra\ -pedantic\ -I$(HEADER_DIR)\ $(C_INPUT_FLAGS) --no-print-directory


debug:
	@make re C_FLAGS_INPUT=-g\ -g3 --no-print-directory
	@gdb ./$(TARGET_NAME) -ex "break main" -ex "run $(GDB_ARGV)"

valgrind:
	@make re C_FLAGS_INPUT=-g\ -g3 --no-print-directory
	@valgrind $(VALGRIND_FLAGS) ./$(TARGET_NAME) $(VALGRIND_INJECT)


library: $(LIBRARY)


directories: | $(SOURCE_DIR) $(OBJECT_DIR)


re:	clean all


clean:
	@rm -rf ./$(OBJECT_DIR)/*.o
	@rm -rf ./$(OBJECT_DIR)/*.dp
	@rm -rf ./*.gc*
	@rm -rf ./__*
#	@make -C $(LIBRARY_DIR) clean --no-print-directory


fclean: clean
	@rm -rf ./$(OBJECT_DIR)
	@rm -f ./$(TARGET_NAME)

doc:
	@make -C $(OXDOC_DIR) --no-print-directory


###############################
#### FILE CREATION SECTION ####
###############################


$(TARGET_NAME): $(OBJECTS)
	@$(CC) -o $(TARGET_NAME) $^ $(L_FLAGS)
	@echo -e "--- '\e[32mBUILD SUCCESSFULL\e[39m ---"


$(LIBRARY):
	@make -C $(LIBRARY_DIR) re --no-print-directory


$(OBJECT_DIR):
	@mkdir -p $@


$(SOURCE_DIR):
	@echo "Error: source folder is not detected"


###############################
#### PATTERN RULES SECTION ####
###############################


__% : $(TESTS_DIR)/__%.c $(SOURCE_DIR)/%.c $(NON_M_OBJECTS)
	@$(CC) -o __$* $(patsubst %$*.o,, $^) \
					-lcriterion $(C_FLAGS) $(L_FLAGS)
	@./__$*


__%_gc : $(TESTS_DIR)/__%.c $(SOURCE_DIR)/%.c $(NON_M_OBJECTS)
	@$(CC) -o __$* $(patsubst %$*.o,, $^) \
					-lcriterion $(C_FLAGS) $(L_FLAGS) $(COV_FLAGS)
	@./__$* && gcov -k $*


$(OBJECT_DIR)/%.o : %.c
	@$(CC) -c -o $@ $< $(C_FLAGS)
	@echo -e "--- '\e[34m$@\e[39m'\t\e[32mSUCCESSFULLY COMPILED\e[39m ---"


$(OBJECT_DIR)/%_cov.o : %.c
	@$(CC) -c -o $@ $< $(C_FLAGS) $(COV_FLAGS)
	@echo -e "--- '\e[34m$@\e[39m'\t\e[32mSUCCESSFULLY COMPILED\e[39m ---"


__%.o : __%.c
	@$(CC) -c -o $(OBJECT_DIR)/$@ $< $(C_FLAGS) -lcriterion

