package system

import "core:os"
import "core:strconv"
import "core:strings"

CPU_Snapshot :: struct {
    total : u64,
    idle  : u64,
}

CPU_Info :: struct {
    model:       string,
    cores:       int,
    usage:       f64,
    load_1m:     f64,
    load_5m:     f64,
    load_15m:    f64,
}

get_cpu_info :: proc(previous: CPU_Snapshot, current: CPU_Snapshot) -> CPU_Info {
    model := get_cpu_model()
    cores := get_cpu_cores()

    usage := calculate_cpu_usage(previous, current)

    load_1m, load_5m, load_15m := get_cpu_load()

    return CPU_Info{
        model    = model,
        cores    = cores,
        usage    = usage,
        load_1m  = load_1m,
        load_5m  = load_5m,
        load_15m = load_15m,
    }
}

get_cpu_model :: proc() -> string {
    data, err := os.read_entire_file_from_path(
        "/proc/cpuinfo",
        context.allocator,
    )

    if err != nil {
        return "unknown"
    }

    lines, ok := strings.split(string(data), "\n")

    if ok != nil {
        return "unknown"
    }

    for &line in lines {
        line = strings.trim(line, " \t\r")

        if strings.index(line, "model name") == 0 ||
           strings.index(line, "Model") == 0 {

            colon := strings.index(line, ":")

            if colon != -1 {
                return strings.trim(line[colon+1:], " \t")
            }
        }
    }

    return "unknown"
}

get_cpu_cores :: proc() -> int {
    data, err := os.read_entire_file_from_path(
        "/proc/cpuinfo",
        context.allocator,
    )

    if err != nil {
        return 0
    }

    lines, ok := strings.split(string(data), "\n")

    if ok != nil {
        return 0
    }

    cores := 0

    for &line in lines {
        line = strings.trim(line, " \t\r")

        if strings.index(line, "processor") == 0 {
            cores += 1
        }
    }

    return cores
}

get_cpu_snapshot :: proc() -> (CPU_Snapshot, bool) {
    data, err := os.read_entire_file_from_path(
        "/proc/stat", 
        context.allocator,
    )

    if err != nil {
        return {}, false
    }

    lines, ok := strings.split(string(data), "\n")

    if ok != nil {
        return {}, false
    }

    for &line in lines {
        line = strings.trim(line, " \t\r")

        if strings.index(line, "cpu ") != 0 {
            continue
        }

        parts, err := strings.split(line, " ")

        if err != nil {
            return {}, false
        }

        values: [8]u64
        count := 0

        for &part in parts {
            part = strings.trim(part, " \t")

            if part == "" || part == "cpu" {
                continue
            }

            if count >= len(values) {
                break
            }

            value, ok := strconv.parse_u64(part)

            if !ok {
                return {}, false
            }

            values[count] = value
            count += 1
        }

        if count < 4 {
            return {}, false
        }

        // /proc/stat:
        //
        // user nice system idle iowait irq softirq steal
        //
        // We include all CPU counters in total.
        total: u64

        for i in 0..<count {
            total += values[i]
        }

        // idle includes idle + iowait.
        idle := values[3]

        if count > 4 {
            idle += values[4]
        }

        return CPU_Snapshot{
            total = total,
            idle  = idle,
        }, true
    }

    return {}, false
}

calculate_cpu_usage :: proc(
    previous: CPU_Snapshot,
    current: CPU_Snapshot,
) -> f64 {
    total_delta := current.total - previous.total
    idle_delta := current.idle - previous.idle

    if total_delta == 0 {
        return 0
    }

    return 100.0 * (1.0 - f64(idle_delta) / f64(total_delta))
}

get_cpu_load :: proc() -> (f64, f64, f64) {
    data, err := os.read_entire_file_from_path(
        "/proc/loadavg",
        context.allocator,
    )

    if err != nil {
        return 0, 0, 0
    }

    parts, ok := strings.split(string(data), " ")

    if ok != nil || len(parts) < 3 {
        return 0, 0, 0
    }

    load_1m, ok1 := strconv.parse_f64(parts[0])
    load_5m, ok2 := strconv.parse_f64(parts[1])
    load_15m, ok3 := strconv.parse_f64(parts[2])

    if !ok1 || !ok2 || !ok3 {
        return 0, 0, 0
    }

    return load_1m, load_5m, load_15m
}