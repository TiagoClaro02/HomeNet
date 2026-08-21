package api

import "core:fmt"
import "../system"
import "../network"

API_Data :: struct {
    system:  system.System_Info,
    network: network.Network_Info,
}

data: API_Data

set_data :: proc(system_info: system.System_Info, network_info: network.Network_Info) {
    data.system = system_info
    data.network = network_info
}

get_status_json :: proc() -> string {
    s := data.system
    n := data.network

    response := fmt.aprintf(
        `{{"system":{{"hostname":"%s","architecture":"%s","uptime":%.2f,"memory":{{"total":%d,"available":%d,"used":%d}},"cpu":{{"model":"%s","cores":%d,"usage":%.2f,"load_1m":%.2f,"load_5m":%.2f,"load_15m":%.2f}},"disk":{{"total":%d,"free":%d,"used":%d}}}},"network":{{"interfaces":[`,
        s.hostname,
        s.architecture,
        s.uptime,

        s.memory.total,
        s.memory.available,
        s.memory.used,

        s.cpu.model,
        s.cpu.cores,
        s.cpu.usage,
        s.cpu.load_1m,
        s.cpu.load_5m,
        s.cpu.load_15m,

        s.disk.total,
        s.disk.free,
        s.disk.used,
    )

    for i in 0..<len(n.interfaces) {
        iface := n.interfaces[i]
        if i > 0 {
            response = fmt.aprintf("%s,", response)
        }

        response = fmt.aprintf(
            `%s{{"name":"%s","stats":{{"rx_bytes":%d,"rx_packets":%d,"rx_errors":%d,"rx_dropped":%d,"tx_bytes":%d,"tx_packets":%d,"tx_errors":%d,"tx_dropped":%d}}}}`,
            response,
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

    response = fmt.aprintf(
        `%s],"connections":{{"default_gateway":"%s","dns_servers":[`,
        response,
        n.connections.default_gateway,
    )

    for i in 0..<len(n.connections.dns_servers) {
        dns := n.connections.dns_servers[i]
        if i > 0 {
            response = fmt.aprintf("%s,", response)
        }

        response = fmt.aprintf(
            `%s"%s"`,
            response,
            dns,
        )
    }

    response = fmt.aprintf(
        `%s],"addresses":[`,
        response,
    )

    for i in 0..<len(n.connections.addresses) {

        addr := n.connections.addresses[i]

        if i > 0 {
            response = fmt.aprintf("%s,", response)
        }

        response = fmt.aprintf(
            `%s{{"interface":"%s","address":"%s","prefix":%d}}`,
            response,
            addr.interface,
            addr.address,
            addr.prefix,
        )
    }

    response = fmt.aprintf(
        `%s],"routes":[`,
        response,
    )

    for i in 0..<len(n.connections.routes) {

        route := n.connections.routes[i]

        if i > 0 {
            response = fmt.aprintf("%s,", response)
        }

        response = fmt.aprintf(
            `%s{{"interface":"%s","destination":"%s","gateway":"%s","metric":%d}}`,
            response,
            route.interface,
            route.destination,
            route.gateway,
            route.metric,
        )
    }

    response = fmt.aprintf(
        `%s]}}}}}}`,
        response,
    )

    return response
}

status_endpoint :: proc() -> string {
    return get_status_json()
}