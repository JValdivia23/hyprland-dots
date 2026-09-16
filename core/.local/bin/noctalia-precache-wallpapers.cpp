#include <iostream>
#include <filesystem>
#include <string>
#include <sstream>
#include <iomanip>
#include <vector>
#include <thread>
#include <mutex>
#include <atomic>
#include <chrono>
#include <unistd.h>

namespace fs = std::filesystem;

// 64-bit FNV-1a hash matching Noctalia's thumbnail cache key
static inline uint64_t fnv1a_64(const std::string& s) {
    uint64_t h = 0xcbf29ce484222325ULL;
    const uint64_t prime = 0x100000001b3ULL;
    for (unsigned char c : s) {
        h ^= c;
        h *= prime;
    }
    return h;
}

static inline std::string to_hex_16(uint64_t h) {
    std::stringstream ss;
    ss << std::hex << std::setw(16) << std::setfill('0') << h;
    return ss.str();
}

struct Job {
    std::string src;
    std::string dst;
};

int main(int argc, char* argv[]) {
    const char* home_env = getenv("HOME");
    std::string home = home_env ? home_env : "";
    if (home.empty()) {
        std::cerr << "Error: HOME environment variable is not set." << std::endl;
        return 1;
    }

    fs::path wp_dir = fs::path(home) / "Pictures/Wallpapers";
    fs::path cache_dir = fs::path(home) / ".cache/noctalia/thumbnails";
    int width = 361;

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--width" && i + 1 < argc) {
            width = std::stoi(argv[++i]);
        } else if (arg == "--cache-dir" && i + 1 < argc) {
            cache_dir = argv[++i];
        } else if (arg == "-h" || arg == "--help") {
            std::cout << "Usage: noctalia-precache-wallpapers [wallpapers_dir] [--width <px>] [--cache-dir <dir>]\n";
            return 0;
        } else if (arg[0] != '-') {
            wp_dir = arg;
        }
    }

    if (!fs::exists(wp_dir)) {
        std::cerr << "Wallpaper directory does not exist: " << wp_dir << std::endl;
        return 1;
    }

    fs::create_directories(cache_dir);

    std::cout << "=======================================================\n";
    std::cout << "       ⚡ Noctalia Wallpaper Pre-cacher (Fast)        \n";
    std::cout << "=======================================================\n";
    std::cout << "Source Directory : " << wp_dir.string() << "\n";
    std::cout << "Thumbnail Cache  : " << cache_dir.string() << "\n";
    std::cout << "Target Width     : " << width << "px\n";
    std::cout << "Scanning wallpapers...\n";

    std::vector<Job> jobs;
    size_t total_scanned = 0;
    size_t already_cached = 0;

    for (auto const& dir_entry : fs::recursive_directory_iterator(wp_dir)) {
        if (!dir_entry.is_regular_file()) continue;
        auto ext = dir_entry.path().extension().string();
        for (auto& c : ext) c = tolower(c);
        if (ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp") continue;

        total_scanned++;
        std::string p = dir_entry.path().string();
        std::error_code ec;
        auto sz = fs::file_size(p, ec);
        if (ec) continue;
        auto mtime = fs::last_write_time(p, ec).time_since_epoch().count();
        if (ec) continue;

        std::string hash_input = p + "\n" + std::to_string(sz) + "\n" + std::to_string(mtime) + "\n" + std::to_string(width) + "\nthumbnail-service-v2";
        std::string hash_name = to_hex_16(fnv1a_64(hash_input)) + ".webp";
        fs::path dst = cache_dir / hash_name;

        if (fs::exists(dst)) {
            already_cached++;
        } else {
            jobs.push_back({p, dst.string()});
        }
    }

    std::cout << "Total Wallpapers : " << total_scanned << "\n";
    std::cout << "Already Cached   : " << already_cached << "\n";
    std::cout << "Jobs to Process  : " << jobs.size() << "\n";
    std::cout << "-------------------------------------------------------\n";

    if (jobs.empty()) {
        std::cout << "✅ All thumbnails are already up to date!\n";
        return 0;
    }

    unsigned int num_threads = std::thread::hardware_concurrency();
    if (num_threads == 0) num_threads = 4;

    std::cout << "Spawning " << num_threads << " parallel worker threads using vipsthumbnail...\n";

    std::atomic<size_t> next_job_idx{0};
    std::atomic<size_t> completed{0};
    std::atomic<size_t> failed{0};
    auto start_time = std::chrono::steady_clock::now();

    std::vector<std::thread> workers;
    workers.reserve(num_threads);

    for (unsigned int t = 0; t < num_threads; ++t) {
        workers.emplace_back([&, width]() {
            while (true) {
                size_t idx = next_job_idx.fetch_add(1);
                if (idx >= jobs.size()) break;

                const auto& job = jobs[idx];
                std::string tmp_dst = job.dst + ".tmp." + std::to_string(getpid()) + "_" + std::to_string(idx) + ".webp";

                std::string cmd = "vipsthumbnail \"" + job.src + "\" --size " + std::to_string(width) + "x -o \"" + tmp_dst + "\" 2>/dev/null";
                int ret = system(cmd.c_str());

                if (ret == 0 && fs::exists(tmp_dst)) {
                    std::error_code ec;
                    fs::rename(tmp_dst, job.dst, ec);
                    if (!ec) {
                        completed.fetch_add(1);
                    } else {
                        fs::remove(tmp_dst, ec);
                        failed.fetch_add(1);
                    }
                } else {
                    fs::remove(tmp_dst);
                    failed.fetch_add(1);
                }

                size_t c = completed.load();
                if (c % 100 == 0 || c == jobs.size()) {
                    float pct = (float)c / jobs.size() * 100.0f;
                    std::cout << "\rProgress: " << c << " / " << jobs.size() << " (" << std::fixed << std::setprecision(1) << pct << "%)" << std::flush;
                }
            }
        });
    }

    for (auto& w : workers) {
        if (w.joinable()) w.join();
    }

    auto end_time = std::chrono::steady_clock::now();
    auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();

    std::cout << "\n-------------------------------------------------------\n";
    std::cout << "✅ Thumbnail pre-caching finished in " << (elapsed_ms / 1000.0f) << "s!\n";
    std::cout << "   Successfully cached : " << completed.load() << "\n";
    if (failed.load() > 0) {
        std::cout << "   Failed              : " << failed.load() << "\n";
    }
    std::cout << "=======================================================\n";

    return 0;
}
