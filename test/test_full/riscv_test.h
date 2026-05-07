#ifndef _ENV_PICORV32_TEST_H
#define _ENV_PICORV32_TEST_H

#ifndef TEST_FUNC_NAME
#  define TEST_FUNC_NAME _start
#  define TEST_FUNC_TXT "_start"
#  define TEST_FUNC_RET mytest_ret
#endif

#define RVTEST_RV32U
#define TESTNUM x28

#define RVTEST_CODE_BEGIN		\
	.text;						\
	.global TEST_FUNC_NAME;		\
	.global TEST_FUNC_RET;		\
TEST_FUNC_NAME:					\

#define RVTEST_PASS				\
	li	a0 , 0x00c0ffee;		\
	jal	zero , TEST_FUNC_RET; 	\

#define RVTEST_FAIL				\
	li	a0 , 0xdeaddead;		\
	jal	zero , TEST_FUNC_RET;	\

#define RVTEST_CODE_END 		\
TEST_FUNC_RET:					\
	.word 0xdead10cc;\
    jal zero , TEST_FUNC_RET;	\

#define RVTEST_DATA_BEGIN .balign 4;
#define RVTEST_DATA_END

#endif
