// signal.h -- C4IX's libc has no signals. Open Adventure only asks for a
// handler that saves on the way out, which c4's systems never call.
#define SIGHUP 1
#define SIGINT 2
#define SIGTERM 15
#define signal(n, h) ((void)0)
