package network

import "core:os"

Network_Info :: struct {
    interfaces: []Network_Interface,
    connections:Network_Connections,
}

get_info :: proc() -> Network_Info {
    interfaces, err := read_interfaces()
    if err != nil {
        return Network_Info{}
    }

    connections := get_connections()

    return Network_Info{
        interfaces = interfaces,
        connections = connections,
    }
}