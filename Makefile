EMACS=$(EMACSX) -nw
ROOT=$(HOME)/.emacs.d
DEPS=-L `pwd` -L $(ROOT)/plugins -L $(ROOT)/custom -L $(ROOT)/plugins/smart-mode-line -L $(ROOT)/elisp -L $(ROOT)/plugins/bookmark+ -L $(ROOT)/plugins/auto-complete
ELC := $(patsubst %.el,%.elc,$(wildcard *.el))

%.elc: %.el
	$(EMACS) -Q -batch $(DEPS) -f batch-byte-compile $<

compile: $(ELC)

clean:
	rm $(ELC)

test:
	@for idx in test/test_*; do \
		printf '* %s\n' $$idx ; \
		./$$idx $(DEPS) ; \
		[ $$? -ne 0 ] && exit 1 ; \
	done; :

.PHONY: compile clean test
