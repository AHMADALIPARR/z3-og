# z3-og crypto module: build and run the known-answer tests.
#
#   make        builds test_crypto
#   make test   builds and runs it (exit status is the test verdict)
#   make clean  removes build outputs

CC ?= gcc
CFLAGS ?= -std=c11 -Wall -Wextra -O2

OBJS = og_sha256.o og_hmac.o og_merkle.o og_mixcolumns.o

test_crypto: test_crypto.o $(OBJS)
	$(CC) $(CFLAGS) -o $@ test_crypto.o $(OBJS)

test_mixcolumns: test_mixcolumns.o og_mixcolumns.o
	$(CC) $(CFLAGS) -o $@ test_mixcolumns.o og_mixcolumns.o

og_sha256.o: og_sha256.c og_sha256.h
	$(CC) $(CFLAGS) -c $< -o $@

og_hmac.o: og_hmac.c og_hmac.h og_sha256.h
	$(CC) $(CFLAGS) -c $< -o $@

og_merkle.o: og_merkle.c og_merkle.h og_sha256.h
	$(CC) $(CFLAGS) -c $< -o $@

og_mixcolumns.o: og_mixcolumns.c og_mixcolumns.h
	$(CC) $(CFLAGS) -c $< -o $@

test_mixcolumns.o: test_mixcolumns.c og_mixcolumns.h
	$(CC) $(CFLAGS) -c $< -o $@

test_crypto.o: test_crypto.c og_sha256.h og_hmac.h og_merkle.h
	$(CC) $(CFLAGS) -c $< -o $@

test: test_crypto test_mixcolumns
	./test_crypto
	./test_mixcolumns

clean:
	rm -f test_crypto test_mixcolumns $(OBJS) test_crypto.o test_mixcolumns.o

.PHONY: test clean
