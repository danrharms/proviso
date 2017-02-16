EMACS=emacs
ROOT=$(HOME)/.emacs.d
DEPS=-L `pwd` -L $(ROOT)/plugins -L $(ROOT)/custom -L $(ROOT)/plugins/smart-mode-line -L $(ROOT)/elisp
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