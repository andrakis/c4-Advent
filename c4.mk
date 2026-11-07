# c4.mk -- this game's part of c4's Makefile. c4 includes it from
# games/advent/c4.mk, its submodule, and runs it from c4's root, with c4's
# tools and variables (games/README.md in c4). Without it, c4 builds
# everything else, and test-advent says it was skipped.

# Open Adventure, the units upstream's Makefile builds, with c4lc: the same
# objects for C4IX, the bare machine and C4DOS. Upstream generates dungeon.c
# and dungeon.h from adventure.yaml, which takes Python and PyYAML; here they
# are committed in c4/, and `make advent-dungeon` makes them again.
ADV       := games/advent
ADV_UNITS := main init actions score misc saveresume
ADV_HDRS  := $(wildcard $(ADV)/*.h $(ADV)/c4/*.h $(ADV)/c4/editline/*.h $(ADV)/c4/sys/*.h) \
             $(wildcard src/c4ix/libc/include/*.h src/c4ix/libc/include/sys/*.h)
ADV_CC    := ./c4sp32 -c 400000 src/c4sp/lisp/c4lc.lisp -O $(IMG_G) -mfuse -fno-builtin -c -conforming \
             -I $(ADV)/c4 -I src/c4ix/libc/include -I $(ADV)
advent-objs: $(ADV_UNITS:%=.advent/%.c4o) .advent/dungeon.c4o .advent/adv-readline.c4o
.advent/%.c4o: $(ADV)/%.c $(ADV_HDRS) $(C4LC_LISP) .img_g | c4sp32
	@mkdir -p .advent
	$(ADV_CC) $< $@ > /dev/null
.advent/%.c4o: $(ADV)/c4/%.c $(ADV_HDRS) $(C4LC_LISP) .img_g | c4sp32
	@mkdir -p .advent
	$(ADV_CC) $< $@ > /dev/null
GAME_OBJS += advent-objs
PHONY += advent-objs advent-dungeon

# ... and by gcc for the host, the reference test-advent holds the c4lc build
# to, and which is held to upstream's own transcripts. 32-bit, as c4 is.
ADV_HOST_SRCS := $(ADV_UNITS:%=$(ADV)/%.c) $(ADV)/c4/dungeon.c $(ADV)/c4/adv-readline.c
advent-host: $(ADV_HOST_SRCS) $(ADV_HDRS)
	gcc -m32 -O2 -std=c99 -w -D_DEFAULT_SOURCE -idirafter $(ADV)/c4 -I$(ADV) -I$(ADV)/c4 -o $@ $(ADV_HOST_SRCS)

advent-dungeon:
	cd $(ADV) && python3 -I make_dungeon.py && mv dungeon.c dungeon.h c4/ && python3 -I c4/hoist.py c4/dungeon.c

# test-advent: upstream's own suite, tests/*.log and the transcripts it holds
# them to. gcc's build must print each one exactly (but for ADV_NOHOST: four
# resume files upstream's cheat program makes, and one that reads its .o). The
# c4lc build, on the bare machine, must print every one that needs no options
# and no file to save to. C4's consoles say they are terminals even when
# piped, so the game there writes a prompt and no echo of what it read, where
# upstream's transcript has both: those lines, the file-name prompt, what the
# shell makes of a save log's last line and the blank ones are left out
# of the comparison, and the game's own words are all there. Two long games
# that end by themselves under C4DOS and in C4IX, and in C4IX a game saved by
# one run and resumed by the next.
ADV_NOHOST := badmagic cheatresume cheatresume2 resumefail2 savetamper
ADV_FILT   := awk '/^Welcome to Adventure/{p=1} p' | tr -d '\r' | grep -v -e '^>' -e '^$$' -e '^c4ix:' -e '^sh: ' -e '^File name:'
adv_same    = cat $(2) | $(ADV_FILT) > .adv_t/want; cat $(1) | $(ADV_FILT) | head -n $$(wc -l < .adv_t/want) > .adv_t/got; cmp -s .adv_t/want .adv_t/got
ADV_BOOT   := timeout 1200 node libjs/cli.js -m 64 -d src/c4bb/images/disk src/c4bb/images/c4ix32.c4r
test-advent: advent-host c4bb-images
	@rm -rf .adv_t && mkdir -p .adv_t/t && cp $(ADV)/tests/*.log $(ADV)/tests/*.chk .adv_t/t/
	@cd .adv_t/t && n=0 && for f in *.log; do s=$${f%.log}; \
	   case " $(ADV_NOHOST) " in *" $$s "*) continue ;; esac; \
	   o=$$(sed -n '/#options:/s///p' $$f); \
	   ../../advent-host $$o < $$f > ../$$s.gcc 2>&1; \
	   cmp -s ../$$s.gcc $$s.chk || { echo "test-advent: gcc's $$s differs from upstream's:"; diff $$s.chk ../$$s.gcc | head -20; exit 1; }; \
	   n=$$((n+1)); done; echo "test-advent: gcc prints $$n of upstream's transcripts"
	@n=0; for f in .adv_t/t/*.log; do s=$$(basename $$f .log); \
	   if grep -q -e '#options' -e '\.adv' -e '^save$$' -e '^resume$$' -e '^suspend$$' -e '^pause$$' $$f; then continue; fi; \
	   ( cd src/c4bb/images/games && timeout 300 node ../../../../libjs/cli.js -m 64 -d . advent.c4r ) < $$f > .adv_t/$$s.bare 2>/dev/null; \
	   $(call adv_same,.adv_t/$$s.bare,.adv_t/t/$$s.chk) \
	     || { echo "test-advent: the bare machine's $$s differs:"; diff .adv_t/want .adv_t/got | head -20; exit 1; }; \
	   n=$$((n+1)); done; echo "test-advent: the bare machine plays $$n of them"
	@( cd src/c4bb/images/games && { printf 'advent\n'; cat ../../../../.adv_t/t/defeat.log; printf 'ver\n'; } \
	   | timeout 1200 node ../../../../libjs/cli.js -m 64 -d . ../c4dos32.c4r ) > .adv_t/defeat.dos 2>/dev/null; \
	 $(call adv_same,.adv_t/defeat.dos,.adv_t/t/defeat.chk) \
	   || { echo "test-advent: C4DOS's defeat differs:"; diff .adv_t/want .adv_t/got | head -20; exit 1; }
	@for s in defeat turnpenalties; do \
	   { printf 'advent\n'; cat .adv_t/t/$$s.log; printf 'exit\n'; } | $(ADV_BOOT) > .adv_t/$$s.c4ix 2>/dev/null; \
	   $(call adv_same,.adv_t/$$s.c4ix,.adv_t/t/$$s.chk) \
	     || { echo "test-advent: C4IX's $$s differs:"; diff .adv_t/want .adv_t/got | head -20; exit 1; }; done
	@{ printf 'cd /tmp\nadvent\n'; cat .adv_t/t/saveresume.1.log; printf 'advent\n'; cat .adv_t/t/saveresume.2.log; printf 'exit\n'; } \
	   | $(ADV_BOOT) > .adv_t/save.c4ix 2>/dev/null; \
	 cat .adv_t/t/saveresume.1.chk .adv_t/t/saveresume.2.chk > .adv_t/save.chk; \
	 $(call adv_same,.adv_t/save.c4ix,.adv_t/save.chk) \
	   || { echo "test-advent: saving and resuming in C4IX differs:"; diff .adv_t/want .adv_t/got | head -20; exit 1; }
	@rm -rf .adv_t && echo "test-advent: OK"
GAME_TESTS += test-advent
PHONY += test-advent
