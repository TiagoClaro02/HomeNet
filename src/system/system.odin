package system

import "core:os"
import "core:strconv"

System_Info :: struct {
    hostname:     string,
    architecture: string,
    uptime:       f64,
    memory:       Memory_Info,
}

get_info :: proc() -> System_Info {

    return System_Info{
        hostname     = get_hostname(),
        architecture = get_architecture(),
        uptime       = get_uptime(),
        memory       = get_memory_info(),
    }
}

get_hostname :: proc() -> string {
    data, err := os.read_entire_file_from_path(
        "/etc/hostname",
        context.allocator,
    )

    if err != nil {
        return "unknown"
    }

    // Remove trailing newline
    if len(data) > 0 && data[len(data)-1] == '\n' {
        data = data[:len(data)-1]
    }

    return string(data)
}

get_architecture :: proc() -> string {
    // We know this machine is ARMv7 for now.
    // We'll replace this with uname shortly.
    return "armv7l"
}

get_uptime :: proc() -> (f64) {
    data, err := os.read_entire_file_from_path(
        "/proc/uptime",
        context.allocator,
    )

    if err != nil {
        return 0
    }

    uptime, _, ok := strconv.parse_f64_prefix(string(data))

    if !ok {
        return 0
    }

    return uptime
}