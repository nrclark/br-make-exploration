default: test.bin

test.txt:
	touch $@

test.bin:
%.bin: %.txt
	export MAKE_TARGET="$@" && \
	export MAKE_DEPS="$^" && \
	env | sort
	cp $< $@

clean:
	rm test.txt test.bin -f
