# c4-images.sh c4ix|bare -- Open Adventure's part of c4's build-images.sh,
# which sources it from c4's root (games/README.md in c4)
case "$1" in
c4ix)
    if ls .advent/*.c4o > /dev/null 2>&1 && [ -f $PB/lib/libc.c4s ]; then
        say "linking Open Adventure for C4IX"
        ./c4rlink32 .advent/*.c4o -l $PB/lib/libc.c4s -o $DISK/c4ix-advent.c4r > /dev/null
    fi ;;
bare)
    if ls .advent/*.c4o > /dev/null 2>&1; then
        item advent
        ./c4rlink32 .advent/*.c4o .libc-bare/libc-*.c4o -o $GAMESDISK/advent.c4r > /dev/null
        GAMES_ON_DISK="$GAMES_ON_DISK ADVENT"
    fi ;;
esac
