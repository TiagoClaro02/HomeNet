package api

import "core:fmt"
import "core:net"
import "core:strings"

Server :: struct {
    socket: net.TCP_Socket,
    port:   int,
}

start :: proc(port: int) -> (Server, bool) {
    endpoint, ok := net.parse_endpoint(fmt.aprintf("0.0.0.0:%d", port))

    if !ok {
        fmt.println("API: invalid endpoint")
        return Server{}, false
    }

    socket, err := net.listen_tcp(endpoint)

    if err != nil {
        fmt.println("API: failed to listen:", err)
        return Server{}, false
    }

    fmt.println("API: listening on port", port)

    return Server{
        socket = socket,
        port = port,
    }, true
}

handle_connection :: proc(server: ^Server) {
    client, source, err := net.accept_tcp(server.socket)

    if err != .None {
        return
    }

    fmt.println("API: connection from", net.endpoint_to_string(source))

    defer net.close(client)

    buffer: [4096]byte

    bytes_read, recv_err := net.recv_tcp(client, buffer[:])

    if recv_err != .None {
        return
    }

    if bytes_read <= 0 {
        return
    }

    request := string(buffer[:bytes_read])

    if !strings.starts_with(request, "GET /api/status ") {
        return
    }

    fmt.println("API REQUEST:")
    fmt.println(request)

    body := get_status_json()

    response := fmt.aprintf(
        "HTTP/1.1 200 OK\r\n" +
        "Content-Type: application/json\r\n" +
        "Access-Control-Allow-Origin: *\r\n" +
        "Content-Length: %d\r\n" +
        "Connection: close\r\n" +
        "\r\n" +
        "%s",
        len(body),
        body,
    )

    response_bytes := transmute([]u8)response

    net.send_tcp(client, response_bytes)
}

run :: proc(server: ^Server) {
    for {
        handle_connection(server)
    }
}