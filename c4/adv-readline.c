// adv-readline.c -- libedit's readline for a game that reads lines: no
// editing and no history. Like libedit, it writes the prompt only to a
// terminal, and a line it returns is the caller's to free and has no newline.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define ADV_LINE 1024

char *readline(const char *prompt) {
	char *buf = malloc(ADV_LINE);
	if (buf == NULL) {
		return NULL;
	}
	if (isatty(0)) {
		fputs(prompt, stdout);
		fflush(stdout);
	}
	if (fgets(buf, ADV_LINE, stdin) == NULL) {
		free(buf);
		return NULL;
	}
	buf[strcspn(buf, "\r\n")] = 0;
	return buf;
}

int add_history(const char *line) {
	return 0;
}
