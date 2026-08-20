package network

import "core:os"
import "core:strconv"
import "core:strings"

read_interfaces :: proc() -> ([]Network_Interface, os.Error) {
	data, err := os.read_entire_file("/proc/net/dev", context.allocator)
	if err != os.ERROR_NONE {
		return nil, err
	}

	text := string(data)

    interfaces: [dynamic]Network_Interface

	for line in strings.split_lines_iterator(&text) {
		trimmed := strings.trim_space(line)

		if trimmed == "" {
			continue
		}

		// Skip the header.
		if strings.has_prefix(line, "Inter-") ||
			strings.has_prefix(line, "face") {
			continue
		}

		// Find the interface name.
		colon := strings.index_rune(line, ':')
		if colon < 0 {
			continue
		}

		name := strings.trim_space(line[:colon])
		values := strings.trim_space(line[colon+1:])

		fields, fields_err := strings.fields(values)
		if fields_err != nil {
			continue
		}

		if len(fields) < 16 {
			continue
		}

		rx_bytes, ok1 := strconv.parse_u64(fields[0])
		rx_packets, ok2 := strconv.parse_u64(fields[1])
		rx_errors, ok3 := strconv.parse_u64(fields[2])
		rx_dropped, ok4 := strconv.parse_u64(fields[3])

		tx_bytes, ok5 := strconv.parse_u64(fields[8])
		tx_packets, ok6 := strconv.parse_u64(fields[9])
		tx_errors, ok7 := strconv.parse_u64(fields[10])
		tx_dropped, ok8 := strconv.parse_u64(fields[11])

		if !(ok1 && ok2 && ok3 && ok4 &&
			ok5 && ok6 && ok7 && ok8) {
			continue
		}

		append(&interfaces, Network_Interface{
			name = name,
			stats = Network_Stats{
				rx_bytes = rx_bytes,
				rx_packets = rx_packets,
				rx_errors = rx_errors,
				rx_dropped = rx_dropped,

				tx_bytes = tx_bytes,
				tx_packets = tx_packets,
				tx_errors = tx_errors,
				tx_dropped = tx_dropped,
			},
		})
	}

	return interfaces[:], os.ERROR_NONE
}