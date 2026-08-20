package main

import "core:fmt"
import "system"

main :: proc() {

    info := system.get_info()

    fmt.println("╔══════════════════════════════════╗")
    fmt.println("║            HomeNet               ║")
    fmt.println("╚══════════════════════════════════╝")
    fmt.println()

    fmt.println("SYSTEM INFO:")
    fmt.printf("Hostname       : %s\n", info.hostname)
    fmt.printf("Architecture   : %s\n", info.architecture)
    fmt.printf("Uptime         : %.2f seconds\n", info.uptime)

    fmt.println("\nMEMORY:")
    fmt.printf("Total          : %d MB\n", info.memory.total / 1024 / 1024)
    fmt.printf("Available      : %d MB\n", info.memory.available / 1024 / 1024)
    fmt.printf("Used           : %d MB\n", info.memory.used / 1024 / 1024)

    fmt.println("\nCPU:")
    fmt.printf("Model          : %s\n", info.cpu.model)
    fmt.printf("Cores          : %d\n", info.cpu.cores)
    fmt.printf("Usage          : %.2f %%\n", info.cpu.usage)
    fmt.printf("Load (1m)      : %.2f\n", info.cpu.load_1m)
    fmt.printf("Load (5m)      : %.2f\n", info.cpu.load_5m)
    fmt.printf("Load (15m)     : %.2f\n", info.cpu.load_15m)

    fmt.println("\nDISK:")
    fmt.printf("Total          : %.2f GB\n", f64(info.disk.total) / 1024 / 1024 / 1024)
    fmt.printf("Free           : %.2f GB\n", f64(info.disk.free)  / 1024 / 1024 / 1024)
    fmt.printf("Used           : %.2f GB\n", f64(info.disk.used)  / 1024 / 1024 / 1024)
}