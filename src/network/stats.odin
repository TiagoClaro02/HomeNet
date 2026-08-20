package network

Network_Stats :: struct {
	rx_bytes:   u64,
	rx_packets: u64,
	rx_errors:  u64,
	rx_dropped: u64,

	tx_bytes:   u64,
	tx_packets: u64,
	tx_errors:  u64,
	tx_dropped: u64,
}

Network_Interface :: struct {
	name:  string,
	stats: Network_Stats,
}