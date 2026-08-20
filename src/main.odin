package main

import "core:fmt"
import "system"
import "network"

main :: proc() {

    system_info := system.get_info()
    network_info := network.get_info()

    fmt.println("╔══════════════════════════════════╗")
    fmt.println("║            HomeNet               ║")
    fmt.println("╚══════════════════════════════════╝")
    fmt.println()

    fmt.println("SYSTEM INFO:")
    fmt.printf("    Hostname       : %s\n", system_info.hostname)
    fmt.printf("    Architecture   : %s\n", system_info.architecture)
    fmt.printf("    Uptime         : %.2f seconds\n", system_info.uptime)

    fmt.println("\nMEMORY:")
    fmt.printf("    Total          : %d MB\n", system_info.memory.total / 1024 / 1024)
    fmt.printf("    Available      : %d MB\n", system_info.memory.available / 1024 / 1024)
    fmt.printf("    Used           : %d MB\n", system_info.memory.used / 1024 / 1024)

    fmt.println("\nCPU:")
    fmt.printf("    Model          : %s\n", system_info.cpu.model)
    fmt.printf("    Cores          : %d\n", system_info.cpu.cores)
    fmt.printf("    Usage          : %.2f %%\n", system_info.cpu.usage)
    fmt.printf("    Load (1m)      : %.2f\n", system_info.cpu.load_1m)
    fmt.printf("    Load (5m)      : %.2f\n", system_info.cpu.load_5m)
    fmt.printf("    Load (15m)     : %.2f\n", system_info.cpu.load_15m)

    fmt.println("\nDISK:")
    fmt.printf("    Total          : %.2f GB\n", f64(system_info.disk.total) / 1024 / 1024 / 1024)
    fmt.printf("    Free           : %.2f GB\n", f64(system_info.disk.free)  / 1024 / 1024 / 1024)
    fmt.printf("    Used           : %.2f GB\n", f64(system_info.disk.used)  / 1024 / 1024 / 1024)

    fmt.println("\nNETWORK:")
    fmt.println(
        "  Interface     RX Bytes       RX Packets   RX Errors   RX Dropped   TX Bytes       TX Packets   TX Errors   TX Dropped",
    )
    for iface in network_info.interfaces {
        fmt.printfln(
            "  %-12s  % 13d  % 11d  % 9d  % 10d  % 13d  % 11d  % 9d  % 10d",
            iface.name,
            iface.stats.rx_bytes,
            iface.stats.rx_packets,
            iface.stats.rx_errors,
            iface.stats.rx_dropped,
            iface.stats.tx_bytes,
            iface.stats.tx_packets,
            iface.stats.tx_errors,
            iface.stats.tx_dropped,
        )
    }

    fmt.println("\nNETWORK CONNECTIONS:")

    fmt.println("  Default Gateway:", network_info.connections.default_gateway)

    fmt.println("  DNS Servers:")
    for dns in network_info.connections.dns_servers {
        fmt.println("    ", dns)
    }

    fmt.println("  Addresses:")
    for addr in network_info.connections.addresses {
        fmt.printf("    %-12s %-15s /%d\n",
            addr.interface,
            addr.address,
            addr.prefix,
        )
    }

    fmt.println("  Routes:")
    for route in network_info.connections.routes {
        fmt.printf("    %-12s %-15s %-15s %d\n",
            route.interface,
            route.destination,
            route.gateway,
            route.metric,
        )
    }

}