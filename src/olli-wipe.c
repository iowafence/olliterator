#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <linux/fs.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define WIPE_BYTES UINT64_C(16777216)

enum {
    RC_USAGE  = 10,
    RC_OPEN   = 20,
    RC_TYPE   = 21,
    RC_SIZE   = 22,
    RC_FRONT  = 30,
    RC_TAIL   = 31,
    RC_FSYNC  = 32
};

static void fail(int rc, const char *msg)
{
    fprintf(stderr, "OLLI-WIPE: FAIL rc=%d: %s\n", rc, msg);
    exit(rc);
}

static uint64_t parse_u64(const char *s)
{
    char *end = NULL;
    errno = 0;

    unsigned long long v = strtoull(s, &end, 10);

    if (errno || !s[0] || !end || *end != '\0' || v == 0)
        fail(RC_USAGE, "invalid expected byte count");

    return (uint64_t)v;
}

static uint64_t get_size(int fd, const struct stat *st)
{
    uint64_t bytes = 0;

    if (S_ISBLK(st->st_mode)) {
        if (ioctl(fd, BLKGETSIZE64, &bytes) != 0)
            fail(RC_OPEN, "BLKGETSIZE64 failed");
        return bytes;
    }

#ifdef OLLI_ALLOW_REGULAR
    if (S_ISREG(st->st_mode))
        return (uint64_t)st->st_size;
#endif

    fail(RC_TYPE, "target is not an authorized device type");
    return 0;
}

static void write_zeros_at(int fd, uint64_t offset, uint64_t length, int rc)
{
    static unsigned char zeros[1024 * 1024];

    if (lseek(fd, (off_t)offset, SEEK_SET) == (off_t)-1)
        fail(rc, "seek failed");

    uint64_t remaining = length;

    while (remaining) {
        size_t chunk = remaining > sizeof(zeros)
                     ? sizeof(zeros)
                     : (size_t)remaining;

        ssize_t n = write(fd, zeros, chunk);

        if (n < 0) {
            if (errno == EINTR)
                continue;
            fail(rc, "write failed");
        }

        if (n == 0)
            fail(rc, "zero-length write");

        remaining -= (uint64_t)n;
    }
}

int main(int argc, char **argv)
{
    if (argc != 3) {
        fprintf(stderr,
                "usage: %s TARGET EXPECTED_BYTES\n",
                argv[0]);
        return RC_USAGE;
    }

    const char *target = argv[1];
    uint64_t expected = parse_u64(argv[2]);

    if (expected < (2ULL * WIPE_BYTES))
        fail(RC_SIZE, "target too small for wipe regions");

    int fd = open(target, O_RDWR | O_CLOEXEC);

    if (fd < 0)
        fail(RC_OPEN, "cannot open target");

    struct stat st;

    if (fstat(fd, &st) != 0)
        fail(RC_OPEN, "cannot stat target");

#ifndef OLLI_ALLOW_REGULAR
    if (!S_ISBLK(st.st_mode))
        fail(RC_TYPE, "production build requires block device");
#else
    if (!S_ISBLK(st.st_mode) && !S_ISREG(st.st_mode))
        fail(RC_TYPE, "test build requires block device or regular file");
#endif

    uint64_t actual = get_size(fd, &st);

    if (actual != expected) {
        fprintf(stderr,
                "OLLI-WIPE: SIZE MISMATCH expected=%" PRIu64
                " actual=%" PRIu64 "\n",
                expected, actual);
        close(fd);
        return RC_SIZE;
    }

    printf("OLLI-WIPE: target=%s\n", target);
    printf("OLLI-WIPE: authenticated-bytes=%" PRIu64 "\n", actual);
    printf("OLLI-WIPE: front-bytes=%" PRIu64 "\n", WIPE_BYTES);
    printf("OLLI-WIPE: tail-offset=%" PRIu64 "\n", actual - WIPE_BYTES);
    fflush(stdout);

    write_zeros_at(fd, 0, WIPE_BYTES, RC_FRONT);
    printf("OLLI-WIPE: FRONT PASS\n");
    fflush(stdout);

    write_zeros_at(fd, actual - WIPE_BYTES, WIPE_BYTES, RC_TAIL);
    printf("OLLI-WIPE: TAIL PASS\n");
    fflush(stdout);

    if (fsync(fd) != 0)
        fail(RC_FSYNC, "fsync failed");

    if (close(fd) != 0)
        fail(RC_FSYNC, "close failed");

    printf("OLLI-WIPE: FSYNC PASS\n");
    printf("OLLI-WIPE: PASS\n");

    return 0;
}
