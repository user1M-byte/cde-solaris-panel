# Builds the lock-screen saver. Needs CDE's development headers/libraries (Dt/Saver.h,
# libDtSvc) plus libXt, libXpm and libX11. Adjust CDE_PREFIX if CDE lives elsewhere.
CDE_PREFIX ?= /usr/dt
CFLAGS ?= -O2 -Wall
sunlock-saver: sunlock-saver.c
	$(CC) $(CFLAGS) -I$(CDE_PREFIX)/include -o $@ $< -L$(CDE_PREFIX)/lib -Wl,-rpath,$(CDE_PREFIX)/lib -lDtSvc -lDtXinerama -ltt -lXm -lXt -lXpm -lX11
clean:
	rm -f sunlock-saver
.PHONY: clean
