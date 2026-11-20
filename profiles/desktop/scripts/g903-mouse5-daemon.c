// g903-mouse5-daemon.c
// Low-latency evdev + uinput passthrough daemon for Logitech G903 LIGHTSPEED.
// Intercepts MOUSE5 (BTN_EXTRA / 276) when enabled and emits a statistically
// human fast double-press of the configured key (default: '2') on a persistent
// virtual uinput keyboard.
//
// Runtime controls:
//   SIGUSR1 -> Toggle active/passthrough mode without dropping device grabs
//   SIGUSR2 -> Reload target key & speed profile from ~/.config/g903-mouse5/{key,speed}

#define _GNU_SOURCE
#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <math.h>
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/eventfd.h>
#include <sys/ioctl.h>
#include <sys/random.h>
#include <time.h>
#include <unistd.h>

#define BY_ID_PATH "/dev/input/by-id/usb-Logitech_USB_Receiver-if02-event-mouse"
#define DEFAULT_KEY_NAME "2"
#define DEFAULT_KEY_CODE KEY_2
#define MAX_FRAME_EVENTS 64
#define BITS_PER_LONG (sizeof(unsigned long) * 8)
#define NBITS(x) ((((x) - 1) / BITS_PER_LONG) + 1)
#define TEST_BIT(bit, arr) (((arr)[(bit) / BITS_PER_LONG] >> ((bit) % BITS_PER_LONG)) & 1UL)

// Human double-press timing profiles (milliseconds).
typedef struct {
    const char *name;
    double hold1_med_ms;
    double hold1_sigma;
    double hold1_min_ms;
    double hold1_max_ms;

    double gap_med_ms;
    double gap_sigma;
    double gap_min_ms;
    double gap_max_ms;

    double hold2_med_ms;
    double hold2_sigma;
    double hold2_min_ms;
    double hold2_max_ms;

    double min_iti_ms;
    double max_iti_ms;
} TimingProfile;

enum {
    SPEED_PEAK = 0,
    SPEED_FAST = 1,
};

static const TimingProfile SPEED_PROFILES[] = {
    [SPEED_PEAK] = {
        .name = "peak",
        .hold1_med_ms = 42.0, .hold1_sigma = 0.14, .hold1_min_ms = 30.0, .hold1_max_ms = 53.0,
        .gap_med_ms   = 46.0, .gap_sigma   = 0.18, .gap_min_ms   = 32.0, .gap_max_ms   = 62.0,
        .hold2_med_ms = 44.0, .hold2_sigma = 0.15, .hold2_min_ms = 30.0, .hold2_max_ms = 56.0,
        .min_iti_ms   = 78.0, .max_iti_ms  = 107.0,
    },
    [SPEED_FAST] = {
        .name = "fast",
        .hold1_med_ms = 54.0, .hold1_sigma = 0.14, .hold1_min_ms = 38.0, .hold1_max_ms = 68.0,
        .gap_med_ms   = 56.0, .gap_sigma   = 0.18, .gap_min_ms   = 38.0, .gap_max_ms   = 76.0,
        .hold2_med_ms = 57.0, .hold2_sigma = 0.15, .hold2_min_ms = 38.0, .hold2_max_ms = 73.0,
        .min_iti_ms   = 88.0, .max_iti_ms  = 134.0,
    },
};

typedef struct {
    const char *name;
    uint16_t code;
} KeyEntry;

static const KeyEntry KEY_MAP[] = {
    {"0", KEY_0}, {"1", KEY_1}, {"2", KEY_2}, {"3", KEY_3}, {"4", KEY_4},
    {"5", KEY_5}, {"6", KEY_6}, {"7", KEY_7}, {"8", KEY_8}, {"9", KEY_9},
    {"a", KEY_A}, {"b", KEY_B}, {"c", KEY_C}, {"d", KEY_D}, {"e", KEY_E},
    {"f", KEY_F}, {"g", KEY_G}, {"h", KEY_H}, {"i", KEY_I}, {"j", KEY_J},
    {"k", KEY_K}, {"l", KEY_L}, {"m", KEY_M}, {"n", KEY_N}, {"o", KEY_O},
    {"p", KEY_P}, {"q", KEY_Q}, {"r", KEY_R}, {"s", KEY_S}, {"t", KEY_T},
    {"u", KEY_U}, {"v", KEY_V}, {"w", KEY_W}, {"x", KEY_X}, {"y", KEY_Y},
    {"z", KEY_Z},
    {"f1", KEY_F1},   {"f2", KEY_F2},   {"f3", KEY_F3},   {"f4", KEY_F4},
    {"f5", KEY_F5},   {"f6", KEY_F6},   {"f7", KEY_F7},   {"f8", KEY_F8},
    {"f9", KEY_F9},   {"f10", KEY_F10}, {"f11", KEY_F11}, {"f12", KEY_F12},
    {"f13", KEY_F13}, {"f14", KEY_F14}, {"f15", KEY_F15}, {"f16", KEY_F16},
    {"f17", KEY_F17}, {"f18", KEY_F18}, {"f19", KEY_F19}, {"f20", KEY_F20},
    {"f21", KEY_F21}, {"f22", KEY_F22}, {"f23", KEY_F23}, {"f24", KEY_F24},
    {"space", KEY_SPACE}, {"tab", KEY_TAB}, {"enter", KEY_ENTER}, {"return", KEY_ENTER},
    {"esc", KEY_ESC}, {"escape", KEY_ESC}, {"capslock", KEY_CAPSLOCK},
    {"grave", KEY_GRAVE}, {"`", KEY_GRAVE},
    {"minus", KEY_MINUS}, {"-", KEY_MINUS},
    {"equal", KEY_EQUAL}, {"=", KEY_EQUAL},
    {"[", KEY_LEFTBRACE}, {"]", KEY_RIGHTBRACE},
    {";", KEY_SEMICOLON}, {"'", KEY_APOSTROPHE},
    {"\\", KEY_BACKSLASH}, {",", KEY_COMMA}, {".", KEY_DOT}, {"/", KEY_SLASH},
    {"kp0", KEY_KP0}, {"kp1", KEY_KP1}, {"kp2", KEY_KP2}, {"kp3", KEY_KP3},
    {"kp4", KEY_KP4}, {"kp5", KEY_KP5}, {"kp6", KEY_KP6}, {"kp7", KEY_KP7},
    {"kp8", KEY_KP8}, {"kp9", KEY_KP9},
};

static atomic_bool g_running = true;
static atomic_bool g_enabled = true;
static atomic_bool g_in_flight = false;
static atomic_bool g_toggle_requested = false;
static atomic_bool g_reload_cfg_requested = false;
static atomic_uint g_target_key = DEFAULT_KEY_CODE;
static atomic_uint g_speed_profile = SPEED_PEAK;

static int g_uinput_mouse_fd = -1;
static int g_uinput_kbd_fd = -1;
static int g_trig_efd = -1;
static char g_state_path[512] = {0};
static char g_pid_path[512] = {0};
static char g_key_cfg_path[512] = {0};
static char g_speed_cfg_path[512] = {0};

// xoshiro256** PRNG state (worker thread only)
static uint64_t g_rng_state[4];

static bool lookup_key_code(const char *raw, uint16_t *out_code, char *out_norm, size_t norm_sz) {
    if (!raw || !raw[0]) return false;
    char buf[64];
    size_t j = 0;
    for (size_t i = 0; raw[i] != '\0' && j + 1 < sizeof(buf); i++) {
        unsigned char ch = (unsigned char)raw[i];
        if (isspace(ch)) continue;
        buf[j++] = (char)tolower(ch);
    }
    buf[j] = '\0';
    if (j == 0) return false;

    const char *s = buf;
    if (strncmp(s, "key_", 4) == 0 && s[4] != '\0') s += 4;

    for (size_t i = 0; i < sizeof(KEY_MAP) / sizeof(KEY_MAP[0]); i++) {
        if (strcmp(s, KEY_MAP[i].name) == 0) {
            if (out_code) *out_code = KEY_MAP[i].code;
            if (out_norm && norm_sz > 0) snprintf(out_norm, norm_sz, "%s", KEY_MAP[i].name);
            return true;
        }
    }
    return false;
}

static bool lookup_speed_profile(const char *raw, unsigned int *out_idx, char *out_norm, size_t norm_sz) {
    if (!raw || !raw[0]) return false;
    char buf[32];
    size_t j = 0;
    for (size_t i = 0; raw[i] != '\0' && j + 1 < sizeof(buf); i++) {
        unsigned char ch = (unsigned char)raw[i];
        if (isspace(ch)) continue;
        buf[j++] = (char)tolower(ch);
    }
    buf[j] = '\0';
    for (unsigned int i = 0; i < (unsigned int)(sizeof(SPEED_PROFILES) / sizeof(SPEED_PROFILES[0])); i++) {
        if (strcmp(buf, SPEED_PROFILES[i].name) == 0) {
            if (out_idx) *out_idx = i;
            if (out_norm && norm_sz > 0) snprintf(out_norm, norm_sz, "%s", SPEED_PROFILES[i].name);
            return true;
        }
    }
    return false;
}

static void reload_config_files(void) {
    if (g_key_cfg_path[0]) {
        int fd = open(g_key_cfg_path, O_RDONLY);
        if (fd >= 0) {
            char buf[64] = {0};
            ssize_t n = read(fd, buf, sizeof(buf) - 1);
            close(fd);
            if (n > 0) {
                uint16_t code = 0;
                if (lookup_key_code(buf, &code, NULL, 0)) {
                    atomic_store(&g_target_key, code);
                }
            }
        }
    }
    if (g_speed_cfg_path[0]) {
        int fd = open(g_speed_cfg_path, O_RDONLY);
        if (fd >= 0) {
            char buf[32] = {0};
            ssize_t n = read(fd, buf, sizeof(buf) - 1);
            close(fd);
            if (n > 0) {
                unsigned int idx = 0;
                if (lookup_speed_profile(buf, &idx, NULL, 0)) {
                    atomic_store(&g_speed_profile, idx);
                }
            }
        }
    }
}

static inline uint64_t rotl64(uint64_t x, int k) {
    return (x << k) | (x >> (64 - k));
}

static uint64_t splitmix64(uint64_t *x) {
    uint64_t z = (*x += 0x9e3779b97f4a7c15ULL);
    z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9ULL;
    z = (z ^ (z >> 27)) * 0x94d049bb133111ebULL;
    return z ^ (z >> 31);
}

static void rng_init(void) {
    uint64_t seed[4] = {0};
    ssize_t n = getrandom(seed, sizeof(seed), 0);
    if (n != (ssize_t)sizeof(seed)) {
        struct timespec ts;
        clock_gettime(CLOCK_MONOTONIC, &ts);
        uint64_t s = ((uint64_t)ts.tv_nsec << 32) ^ (uint64_t)ts.tv_sec ^ (uint64_t)getpid();
        for (int i = 0; i < 4; i++) {
            seed[i] = splitmix64(&s);
        }
    }
    memcpy(g_rng_state, seed, sizeof(g_rng_state));
}

static uint64_t rng_next(void) {
    const uint64_t result = rotl64(g_rng_state[1] * 5, 7) * 9;
    const uint64_t t = g_rng_state[1] << 17;
    g_rng_state[2] ^= g_rng_state[0];
    g_rng_state[3] ^= g_rng_state[1];
    g_rng_state[1] ^= g_rng_state[2];
    g_rng_state[0] ^= g_rng_state[3];
    g_rng_state[2] ^= t;
    g_rng_state[3] = rotl64(g_rng_state[3], 45);
    return result;
}

static double rng_uniform01(void) {
    uint64_t r = rng_next() >> 11;
    return ((double)r + 0.5) * (1.0 / 9007199254740992.0);
}

static double rng_normal(void) {
    double u1 = rng_uniform01();
    double u2 = rng_uniform01();
    return sqrt(-2.0 * log(u1)) * cos(6.28318530717958647692 * u2);
}

static double sample_lognormal_bounded(double median_ms, double sigma, double min_ms, double max_ms) {
    // Rejection-sample inside [min_ms, max_ms] so the upper/lower caps stay smooth without pile-up spikes.
    for (int attempt = 0; attempt < 16; attempt++) {
        double val = median_ms * exp(sigma * rng_normal());
        if (val >= min_ms && val <= max_ms) return val;
    }
    double val = median_ms * exp(sigma * rng_normal());
    if (val < min_ms) val = min_ms;
    if (val > max_ms) val = max_ms;
    return val;
}

static void sleep_precise_ms(double ms) {
    if (ms <= 0.0) return;
    struct timespec target;
    clock_gettime(CLOCK_MONOTONIC, &target);
    int64_t ns = (int64_t)(ms * 1000000.0);
    target.tv_sec += ns / 1000000000LL;
    target.tv_nsec += ns % 1000000000LL;
    if (target.tv_nsec >= 1000000000LL) {
        target.tv_sec += 1;
        target.tv_nsec -= 1000000000LL;
    }
    int rc;
    do {
        rc = clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &target, NULL);
    } while (rc == EINTR && atomic_load(&g_running));
}

static void write_state_file(bool state) {
    if (!g_state_path[0]) return;
    int fd = open(g_state_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd >= 0) {
        const char *s = state ? "1\n" : "0\n";
        ssize_t unused = write(fd, s, 2);
        (void)unused;
        close(fd);
    }
}

static void write_pid_file(void) {
    if (!g_pid_path[0]) return;
    int fd = open(g_pid_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd >= 0) {
        char buf[32];
        int len = snprintf(buf, sizeof(buf), "%d\n", (int)getpid());
        if (len > 0) {
            ssize_t unused = write(fd, buf, (size_t)len);
            (void)unused;
        }
        close(fd);
    }
}

static void handle_sigusr1(int sig) {
    (void)sig;
    atomic_store(&g_toggle_requested, true);
}

static void handle_sigusr2(int sig) {
    (void)sig;
    atomic_store(&g_reload_cfg_requested, true);
}

static void handle_sigterm(int sig) {
    (void)sig;
    atomic_store(&g_running, false);
    if (g_trig_efd >= 0) {
        uint64_t one = 1;
        ssize_t unused = write(g_trig_efd, &one, sizeof(one));
        (void)unused;
    }
}

static int write_all(int fd, const void *buf, size_t len) {
    const uint8_t *p = (const uint8_t *)buf;
    size_t sent = 0;
    while (sent < len) {
        ssize_t n = write(fd, p + sent, len - sent);
        if (n < 0) {
            if (errno == EINTR) continue;
            return -1;
        }
        sent += (size_t)n;
    }
    return 0;
}

static void emit_key_event(int uinput_fd, uint16_t code, int32_t value) {
    struct input_event evs[2];
    memset(evs, 0, sizeof(evs));
    struct timeval tv;
    gettimeofday(&tv, NULL);

    evs[0].time = tv;
    evs[0].type = EV_KEY;
    evs[0].code = code;
    evs[0].value = value;

    evs[1].time = tv;
    evs[1].type = EV_SYN;
    evs[1].code = SYN_REPORT;
    evs[1].value = 0;

    write_all(uinput_fd, evs, sizeof(evs));
}

static void *macro_worker(void *arg) {
    (void)arg;
    rng_init();

    while (atomic_load(&g_running)) {
        uint64_t val = 0;
        ssize_t n = read(g_trig_efd, &val, sizeof(val));
        if (n < 0) {
            if (errno == EINTR) continue;
            break;
        }
        if (!atomic_load(&g_running)) break;

        // Snapshot target key and timing profile once for this press sequence
        uint16_t key_code = (uint16_t)atomic_load(&g_target_key);
        unsigned int speed_idx = atomic_load(&g_speed_profile);
        if (speed_idx >= (unsigned int)(sizeof(SPEED_PROFILES) / sizeof(SPEED_PROFILES[0]))) {
            speed_idx = SPEED_PEAK;
        }
        const TimingProfile *prof = &SPEED_PROFILES[speed_idx];

        // Rejection-sample (h1, gap) inside [min_iti_ms, max_iti_ms] to eliminate slow outliers cleanly
        double h1 = 0.0, gap = 0.0;
        for (int attempt = 0; attempt < 16; attempt++) {
            h1 = sample_lognormal_bounded(
                prof->hold1_med_ms, prof->hold1_sigma,
                prof->hold1_min_ms, prof->hold1_max_ms);
            gap = sample_lognormal_bounded(
                prof->gap_med_ms, prof->gap_sigma,
                prof->gap_min_ms, prof->gap_max_ms);
            if (h1 + gap >= prof->min_iti_ms && h1 + gap <= prof->max_iti_ms) {
                break;
            }
        }
        if (h1 + gap < prof->min_iti_ms) gap = prof->min_iti_ms - h1;
        if (h1 + gap > prof->max_iti_ms) gap = prof->max_iti_ms - h1;

        double h2 = sample_lognormal_bounded(
            prof->hold2_med_ms, prof->hold2_sigma,
            prof->hold2_min_ms, prof->hold2_max_ms);

        // Emit first press immediately (< 0.1 ms latency)
        emit_key_event(g_uinput_kbd_fd, key_code, 1);
        sleep_precise_ms(h1);
        emit_key_event(g_uinput_kbd_fd, key_code, 0);

        sleep_precise_ms(gap);

        emit_key_event(g_uinput_kbd_fd, key_code, 1);
        sleep_precise_ms(h2);
        emit_key_event(g_uinput_kbd_fd, key_code, 0);

        atomic_store(&g_in_flight, false);
    }

    return NULL;
}

static int create_uinput_mouse(void) {
    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
        perror("open /dev/uinput (mouse)");
        return -1;
    }

    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_REL);
    ioctl(fd, UI_SET_EVBIT, EV_MSC);

    ioctl(fd, UI_SET_MSCBIT, MSC_SCAN);

    // Standard mouse buttons (256, 272..287); omit REL_WHEEL_HI_RES for XWayland compatibility
    ioctl(fd, UI_SET_KEYBIT, BTN_0);
    for (int code = BTN_LEFT; code <= BTN_TASK + 8; code++) {
        ioctl(fd, UI_SET_KEYBIT, code);
    }

    ioctl(fd, UI_SET_RELBIT, REL_X);
    ioctl(fd, UI_SET_RELBIT, REL_Y);
    ioctl(fd, UI_SET_RELBIT, REL_WHEEL);
    ioctl(fd, UI_SET_RELBIT, REL_HWHEEL);

    struct uinput_setup usetup;
    memset(&usetup, 0, sizeof(usetup));
    usetup.id.bustype = BUS_VIRTUAL;
    usetup.id.vendor  = 0x046d;
    usetup.id.product = 0x4087;
    usetup.id.version = 0x0111;
    snprintf(usetup.name, UINPUT_MAX_NAME_SIZE, "Logitech G903 Virtual Mouse");

    if (ioctl(fd, UI_DEV_SETUP, &usetup) < 0 || ioctl(fd, UI_DEV_CREATE) < 0) {
        perror("UI_DEV_CREATE (mouse)");
        close(fd);
        return -1;
    }
    return fd;
}

static int create_uinput_keyboard(void) {
    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
        perror("open /dev/uinput (keyboard)");
        return -1;
    }

    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    ioctl(fd, UI_SET_EVBIT, EV_KEY);

    for (int code = KEY_ESC; code <= KEY_MICMUTE; code++) {
        ioctl(fd, UI_SET_KEYBIT, code);
    }

    struct uinput_setup usetup;
    memset(&usetup, 0, sizeof(usetup));
    usetup.id.bustype = BUS_VIRTUAL;
    usetup.id.vendor  = 0x046d;
    usetup.id.product = 0x4087;
    usetup.id.version = 0x0111;
    snprintf(usetup.name, UINPUT_MAX_NAME_SIZE, "Logitech G903 Virtual Keyboard");

    if (ioctl(fd, UI_DEV_SETUP, &usetup) < 0 || ioctl(fd, UI_DEV_CREATE) < 0) {
        perror("UI_DEV_CREATE (keyboard)");
        close(fd);
        return -1;
    }
    return fd;
}

static bool is_g903_mouse_fd(int fd) {
    struct input_id id;
    if (ioctl(fd, EVIOCGID, &id) < 0) return false;
    if (id.bustype != BUS_USB) return false;

    char name[256] = {0};
    if (ioctl(fd, EVIOCGNAME(sizeof(name)), name) < 0) return false;
    if (strstr(name, "Virtual") != NULL) return false;
    if (strstr(name, "G903") == NULL) return false;

    unsigned long ev_bits[NBITS(EV_MAX)] = {0};
    unsigned long rel_bits[NBITS(REL_MAX)] = {0};
    unsigned long key_bits[NBITS(KEY_MAX)] = {0};

    if (ioctl(fd, EVIOCGBIT(0, sizeof(ev_bits)), ev_bits) < 0) return false;
    if (!TEST_BIT(EV_REL, ev_bits) || !TEST_BIT(EV_KEY, ev_bits)) return false;
    if (ioctl(fd, EVIOCGBIT(EV_REL, sizeof(rel_bits)), rel_bits) < 0) return false;
    if (ioctl(fd, EVIOCGBIT(EV_KEY, sizeof(key_bits)), key_bits) < 0) return false;

    return TEST_BIT(REL_X, rel_bits) && TEST_BIT(REL_Y, rel_bits) && TEST_BIT(BTN_EXTRA, key_bits);
}

static int open_g903_device(void) {
    int fd = open(BY_ID_PATH, O_RDONLY | O_NONBLOCK);
    if (fd >= 0) {
        if (is_g903_mouse_fd(fd)) return fd;
        close(fd);
    }

    DIR *dir = opendir("/dev/input");
    if (!dir) return -1;

    struct dirent *ent;
    while ((ent = readdir(dir)) != NULL) {
        if (strncmp(ent->d_name, "event", 5) != 0) continue;
        char path[280];
        snprintf(path, sizeof(path), "/dev/input/%s", ent->d_name);
        fd = open(path, O_RDONLY | O_NONBLOCK);
        if (fd < 0) continue;
        if (is_g903_mouse_fd(fd)) {
            closedir(dir);
            return fd;
        }
        close(fd);
    }
    closedir(dir);
    return -1;
}

static void wait_buttons_released(int fd) {
    for (int attempt = 0; attempt < 40; attempt++) {
        unsigned long key_state[NBITS(KEY_MAX)] = {0};
        if (ioctl(fd, EVIOCGKEY(sizeof(key_state)), key_state) < 0) break;
        bool held = false;
        for (int code = BTN_LEFT; code <= BTN_TASK; code++) {
            if (TEST_BIT(code, key_state)) {
                held = true;
                break;
            }
        }
        if (!held) break;
        usleep(25000);
    }
}

static void flush_frame(struct input_event *frame, int count,
                        bool *btn_extra_passed_down) {
    struct input_event mouse_out[MAX_FRAME_EVENTS];
    struct input_event kbd_out[MAX_FRAME_EVENTS];
    int m_n = 0;
    int k_n = 0;
    bool has_msc = false;
    struct input_event pending_msc = {0};

    for (int i = 0; i < count; i++) {
        struct input_event ev = frame[i];

        if (ev.type == EV_SYN) continue;

        if (ev.type == EV_MSC && ev.code == MSC_SCAN) {
            pending_msc = ev;
            has_msc = true;
            continue;
        }

        if (ev.type == EV_REL) {
            if (ev.code == REL_WHEEL_HI_RES || ev.code == REL_HWHEEL_HI_RES) {
                has_msc = false;
                continue;
            }
            if (m_n < MAX_FRAME_EVENTS - 1) mouse_out[m_n++] = ev;
            has_msc = false;
            continue;
        }

        if (ev.type == EV_KEY) {
            if (ev.code == BTN_EXTRA) {
                bool on = atomic_load(&g_enabled);
                if (ev.value == 1) {
                    if (on) {
                        if (!atomic_exchange(&g_in_flight, true)) {
                            uint64_t one = 1;
                            if (write(g_trig_efd, &one, sizeof(one)) < 0) {
                                atomic_store(&g_in_flight, false);
                            }
                        }
                        has_msc = false;
                        continue;
                    } else {
                        *btn_extra_passed_down = true;
                    }
                } else if (ev.value == 0) {
                    if (*btn_extra_passed_down) {
                        *btn_extra_passed_down = false;
                    } else {
                        has_msc = false;
                        continue;
                    }
                } else {
                    if (!*btn_extra_passed_down) {
                        has_msc = false;
                        continue;
                    }
                }
            }

            bool is_mouse_btn = (ev.code == BTN_0) || (ev.code >= BTN_LEFT && ev.code <= BTN_TASK + 8);
            if (is_mouse_btn) {
                if (has_msc && m_n < MAX_FRAME_EVENTS - 2) {
                    mouse_out[m_n++] = pending_msc;
                }
                if (m_n < MAX_FRAME_EVENTS - 1) mouse_out[m_n++] = ev;
            } else {
                if (k_n < MAX_FRAME_EVENTS - 1) kbd_out[k_n++] = ev;
            }
            has_msc = false;
            continue;
        }

        has_msc = false;
    }

    if (m_n > 0) {
        struct input_event syn = {0};
        syn.time = frame[count - 1].time;
        syn.type = EV_SYN;
        syn.code = SYN_REPORT;
        syn.value = 0;
        mouse_out[m_n++] = syn;
        write_all(g_uinput_mouse_fd, mouse_out, (size_t)m_n * sizeof(struct input_event));
    }

    if (k_n > 0) {
        struct input_event syn = {0};
        syn.time = frame[count - 1].time;
        syn.type = EV_SYN;
        syn.code = SYN_REPORT;
        syn.value = 0;
        kbd_out[k_n++] = syn;
        write_all(g_uinput_kbd_fd, kbd_out, (size_t)k_n * sizeof(struct input_event));
    }
}

static void process_pending_signals(void) {
    if (atomic_exchange(&g_toggle_requested, false)) {
        bool next = !atomic_load(&g_enabled);
        atomic_store(&g_enabled, next);
        write_state_file(next);
    }
    if (atomic_exchange(&g_reload_cfg_requested, false)) {
        reload_config_files();
    }
}

int main(int argc, char **argv) {
    struct sigaction sa_usr1 = {0};
    sa_usr1.sa_handler = handle_sigusr1;
    sa_usr1.sa_flags = SA_RESTART;
    sigaction(SIGUSR1, &sa_usr1, NULL);

    struct sigaction sa_usr2 = {0};
    sa_usr2.sa_handler = handle_sigusr2;
    sa_usr2.sa_flags = SA_RESTART;
    sigaction(SIGUSR2, &sa_usr2, NULL);

    struct sigaction sa_term = {0};
    sa_term.sa_handler = handle_sigterm;
    sigaction(SIGTERM, &sa_term, NULL);
    sigaction(SIGINT, &sa_term, NULL);

    bool start_enabled = true;
    const char *cli_key = NULL;
    const char *cli_speed = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--disabled") == 0) {
            start_enabled = false;
        } else if (strcmp(argv[i], "--key") == 0 && i + 1 < argc) {
            cli_key = argv[++i];
        } else if (strcmp(argv[i], "--speed") == 0 && i + 1 < argc) {
            cli_speed = argv[++i];
        } else if (strcmp(argv[i], "--check-key") == 0 && i + 1 < argc) {
            uint16_t code = 0;
            char norm[32] = {0};
            if (lookup_key_code(argv[i + 1], &code, norm, sizeof(norm))) {
                printf("%s\n", norm);
                return 0;
            }
            return 1;
        } else if (strcmp(argv[i], "--check-speed") == 0 && i + 1 < argc) {
            unsigned int idx = 0;
            char norm[32] = {0};
            if (lookup_speed_profile(argv[i + 1], &idx, norm, sizeof(norm))) {
                printf("%s\n", norm);
                return 0;
            }
            return 1;
        }
    }
    atomic_store(&g_enabled, start_enabled);

    const char *cfg_home = getenv("XDG_CONFIG_HOME");
    const char *home = getenv("HOME");
    if (cfg_home && cfg_home[0]) {
        snprintf(g_key_cfg_path, sizeof(g_key_cfg_path), "%s/g903-mouse5/key", cfg_home);
        snprintf(g_speed_cfg_path, sizeof(g_speed_cfg_path), "%s/g903-mouse5/speed", cfg_home);
    } else if (home && home[0]) {
        snprintf(g_key_cfg_path, sizeof(g_key_cfg_path), "%s/.config/g903-mouse5/key", home);
        snprintf(g_speed_cfg_path, sizeof(g_speed_cfg_path), "%s/.config/g903-mouse5/speed", home);
    }

    reload_config_files();
    if (cli_key) {
        uint16_t code = 0;
        if (!lookup_key_code(cli_key, &code, NULL, 0)) {
            fprintf(stderr, "Unsupported key: %s\n", cli_key);
            return 2;
        }
        atomic_store(&g_target_key, code);
    }
    if (cli_speed) {
        unsigned int idx = 0;
        if (!lookup_speed_profile(cli_speed, &idx, NULL, 0)) {
            fprintf(stderr, "Unsupported speed: %s\n", cli_speed);
            return 2;
        }
        atomic_store(&g_speed_profile, idx);
    }

    const char *runtime_dir = getenv("XDG_RUNTIME_DIR");
    if (runtime_dir && runtime_dir[0]) {
        snprintf(g_state_path, sizeof(g_state_path), "%s/g903-mouse5.state", runtime_dir);
        snprintf(g_pid_path, sizeof(g_pid_path), "%s/g903-mouse5.pid", runtime_dir);
    } else {
        snprintf(g_state_path, sizeof(g_state_path), "/tmp/g903-mouse5-%d.state", (int)getuid());
        snprintf(g_pid_path, sizeof(g_pid_path), "/tmp/g903-mouse5-%d.pid", (int)getuid());
    }

    g_uinput_mouse_fd = create_uinput_mouse();
    g_uinput_kbd_fd = create_uinput_keyboard();
    g_trig_efd = eventfd(0, EFD_CLOEXEC);
    if (g_uinput_mouse_fd < 0 || g_uinput_kbd_fd < 0 || g_trig_efd < 0) {
        return 1;
    }

    usleep(150000);

    pthread_t worker;
    if (pthread_create(&worker, NULL, macro_worker, NULL) != 0) {
        perror("pthread_create");
        return 1;
    }

    write_pid_file();
    write_state_file(atomic_load(&g_enabled));

    while (atomic_load(&g_running)) {
        process_pending_signals();

        int evfd = open_g903_device();
        if (evfd < 0) {
            usleep(500000);
            continue;
        }

        wait_buttons_released(evfd);
        if (ioctl(evfd, EVIOCGRAB, 1) < 0) {
            perror("EVIOCGRAB");
            close(evfd);
            usleep(500000);
            continue;
        }

        struct input_event frame[MAX_FRAME_EVENTS];
        int frame_len = 0;
        bool btn_extra_passed_down = false;

        struct pollfd pfd = { .fd = evfd, .events = POLLIN };
        while (atomic_load(&g_running)) {
            process_pending_signals();

            int prc = poll(&pfd, 1, 250);
            if (prc < 0) {
                if (errno == EINTR) continue;
                break;
            }
            if (prc == 0) continue;

            if (pfd.revents & (POLLERR | POLLHUP | POLLNVAL)) {
                break;
            }

            struct input_event buf[64];
            ssize_t r;
            while ((r = read(evfd, buf, sizeof(buf))) > 0) {
                int n_evs = (int)(r / (ssize_t)sizeof(struct input_event));
                for (int i = 0; i < n_evs; i++) {
                    if (frame_len < MAX_FRAME_EVENTS) {
                        frame[frame_len++] = buf[i];
                    }
                    if (buf[i].type == EV_SYN && buf[i].code == SYN_REPORT) {
                        flush_frame(frame, frame_len, &btn_extra_passed_down);
                        frame_len = 0;
                    }
                }
            }
            if (r < 0 && errno != EAGAIN && errno != EINTR) {
                break;
            }
        }

        ioctl(evfd, EVIOCGRAB, 0);
        close(evfd);
        if (atomic_load(&g_running)) {
            usleep(250000);
        }
    }

    pthread_join(worker, NULL);

    if (g_pid_path[0]) unlink(g_pid_path);
    if (g_state_path[0]) unlink(g_state_path);
    if (g_trig_efd >= 0) close(g_trig_efd);
    if (g_uinput_mouse_fd >= 0) {
        ioctl(g_uinput_mouse_fd, UI_DEV_DESTROY);
        close(g_uinput_mouse_fd);
    }
    if (g_uinput_kbd_fd >= 0) {
        ioctl(g_uinput_kbd_fd, UI_DEV_DESTROY);
        close(g_uinput_kbd_fd);
    }
    return 0;
}
