package system

import "core:os"
import "core:strconv"
import "core:strings"

Memory_Info :: struct {
    total:     u64,
    available: u64,
    used:      u64,
}

get_memory_info :: proc() -> Memory_Info {
    data, err := os.read_entire_file_from_path(
        "/proc/meminfo",
        context.allocator,
    )

    if err != nil {
        return {}
    }

    total:     u64
    available: u64

    lines, _ := strings.split(string(data), "\n")

    for &line in lines {
        line = strings.trim(line, " \t\r\n")

        if strings.index(line, "MemTotal:") == 0 {
            value, ok := parse_meminfo_value(line)

            if ok {
                total = value
            }
        }

        if strings.index(line, "MemAvailable:") == 0 {
            value, ok := parse_meminfo_value(line)

            if ok {
                available = value
            }
        }
    }

    return Memory_Info{
        total     = total,
        available = available,
        used      = total - available,
    }
}

parse_meminfo_value :: proc(line: string) -> (u64, bool) {
    colon := strings.index(line, ":")

    if colon == -1 {
        return 0, false
    }

    value_string := strings.trim(line[colon+1:], " \t")

    // Remove "kB"
    parts, err := strings.split(value_string, " ")

    if err != nil || len(parts) == 0 {
        return 0, false
    }

    value, ok := strconv.parse_u64(parts[0])

    if !ok {
        return 0, false
    }

    // /proc/meminfo reports memory in kB.
    return value * 1024, true
}