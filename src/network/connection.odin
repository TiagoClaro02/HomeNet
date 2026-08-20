package network

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

Network_Address :: struct {
    interface: string,
    address:   string,
    prefix:    int,
}

Network_Route :: struct {
    interface: string,
    destination: string,
    gateway:     string,
    metric:      int,
}

Network_Connections :: struct {
    addresses:       [dynamic]Network_Address,
    routes:          [dynamic]Network_Route,
    dns_servers:     [dynamic]string,
    default_gateway: string,
}

get_connections :: proc() -> Network_Connections {
    result: Network_Connections

    result.addresses = make([dynamic]Network_Address)
    result.routes = make([dynamic]Network_Route)
    result.dns_servers = make([dynamic]string)

    // -------------------------
    // IP addresses
    // -------------------------

    state, stdout, stderr, err := os.process_exec(
        os.Process_Desc{
            command = []string{"ip", "-4", "addr"},
        },
        context.allocator,
    )

    if err == nil && state.success {
        text := string(stdout)

        current_interface := ""

        for line in strings.split_lines_iterator(&text) {
            trimmed := strings.trim_space(line)

            if trimmed == "" {
                continue
            }

            // Interface line:
            // 2: eth0: <BROADCAST,MULTICAST,UP,...>
            if trimmed[0] >= '0' && trimmed[0] <= '9' {
                fields, _ := strings.split_n(trimmed, ":", 3)

                if len(fields) >= 2 {
                    current_interface = strings.trim_space(fields[1])
                }

                continue
            }

            // Address line:
            // inet 192.168.1.160/24 ...
            if strings.has_prefix(trimmed, "inet ") {
                fields, _ := strings.fields(trimmed)

                if len(fields) >= 2 {
                    address_prefix := fields[1]

                    parts, _ := strings.split_n(address_prefix, "/", 2)

                    if len(parts) == 2 {
                        prefix, ok := strconv.parse_int(parts[1])

                        if ok {
                            append(&result.addresses, Network_Address{
                                interface = current_interface,
                                address = parts[0],
                                prefix = prefix,
                            })
                        }
                    }
                }
            }
        }
    }

    // -------------------------
    // Routing table
    // -------------------------

    state, stdout, stderr, err = os.process_exec(
        os.Process_Desc{
            command = []string{"cat", "/proc/net/route"},
        },
        context.allocator,
    )

    if err == nil && state.success {
        text := string(stdout)

        first_line := true

        for line in strings.split_lines_iterator(&text) {
            trimmed := strings.trim_space(line)

            if trimmed == "" {
                continue
            }

            if first_line {
                first_line = false
                continue
            }

            fields, _ := strings.fields(line)

            if len(fields) < 11 {
                continue
            }

            iface := fields[0]
            destination_hex := fields[1]
            gateway_hex := fields[2]
            metric, ok := strconv.parse_int(fields[6])

            if !ok {
                continue
            }

            destination := ipv4_from_proc_hex(destination_hex)
            gateway := ipv4_from_proc_hex(gateway_hex)

            append(&result.routes, Network_Route{
                interface = iface,
                destination = destination,
                gateway = gateway,
                metric = metric,
            })

            if destination_hex == "00000000" {
                result.default_gateway = gateway
            }
        }
    }

    // -------------------------
    // DNS
    // -------------------------

    state, stdout, stderr, err = os.process_exec(
        os.Process_Desc{
            command = []string{"cat", "/etc/resolv.conf"},
        },
        context.allocator,
    )

    if err == nil && state.success {
        text := string(stdout)

        for line in strings.split_lines_iterator(&text) {
            trimmed := strings.trim_space(line)

            if strings.has_prefix(trimmed, "nameserver ") {
                fields, _ := strings.fields(trimmed)

                if len(fields) >= 2 {
                    append(&result.dns_servers, fields[1])
                }
            }
        }
    }

    return result
}

ipv4_from_proc_hex :: proc(value: string) -> string {
    n, ok := strconv.parse_uint(value, 16)
    if !ok {
        return ""
    }

    value_u32 := u32(n)

    if !ok {
        return ""
    }

    a := u8(n & 0xff)
    b := u8((n >> 8) & 0xff)
    c := u8((n >> 16) & 0xff)
    d := u8((n >> 24) & 0xff)

    return fmt.aprintf("%d.%d.%d.%d", a, b, c, d)
}