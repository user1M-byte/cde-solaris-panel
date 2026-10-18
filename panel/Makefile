# Builds the small-icon grid client. Needs a C compiler plus libX11 and libXpm headers
# (Debian/Ubuntu: sudo apt install build-essential libx11-dev libxpm-dev).
CFLAGS ?= -O2 -Wall
bin/fp-grid: src/fp-grid.c
	$(CC) $(CFLAGS) -o $@ $< -lXpm -lX11
clean:
	rm -f bin/fp-grid
.PHONY: clean
