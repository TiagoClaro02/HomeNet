const API_URL = "http://192.168.1.160:8080/api/status";

async function updateDashboard() {
    try {
        console.log("Fetching API...");

        const response = await fetch(API_URL);

        console.log("Response:", response);

        const data = await response.json();

        console.log("JSON:", data);

        document.getElementById("hostname").textContent =
            data.system.hostname;

        document.getElementById("architecture").textContent =
            data.system.architecture;

        document.getElementById("uptime").textContent =
            data.system.uptime.toFixed(2) + " seconds";

        document.getElementById("cpu-usage").textContent =
            data.system.cpu.usage.toFixed(2) + "%";

        document.getElementById("load-1m").textContent =
            data.system.cpu.load_1m.toFixed(2);

        document.getElementById("load-5m").textContent =
            data.system.cpu.load_5m.toFixed(2);

        document.getElementById("load-15m").textContent =
            data.system.cpu.load_15m.toFixed(2);

        document.getElementById("memory-total").textContent =
            formatBytes(data.system.memory.total);

        document.getElementById("memory-used").textContent =
            formatBytes(data.system.memory.used);

        document.getElementById("memory-available").textContent =
            formatBytes(data.system.memory.available);

        document.getElementById("disk-total").textContent =
            formatBytes(data.system.disk.total);

        document.getElementById("disk-used").textContent =
            formatBytes(data.system.disk.used);

        document.getElementById("disk-free").textContent =
            formatBytes(data.system.disk.free);

        document.getElementById("gateway").textContent =
            data.network.connections.default_gateway;

        document.getElementById("dns").textContent =
            data.network.connections.dns_servers.join(", ");

        // Network interfaces
        const interfacesContainer = document.getElementById("interfaces");

        interfacesContainer.innerHTML = "";

        data.network.interfaces.forEach(iface => {
            const div = document.createElement("div");

            div.className = "network-interface";

            div.innerHTML = `
                <strong>${iface.name}</strong>
                <div>RX: ${formatBytes(iface.stats.rx_bytes)}</div>
                <div>TX: ${formatBytes(iface.stats.tx_bytes)}</div>
                <div>RX Packets: ${iface.stats.rx_packets}</div>
                <div>TX Packets: ${iface.stats.tx_packets}</div>
                <div>RX Errors: ${iface.stats.rx_errors}</div>
                <div>TX Errors: ${iface.stats.tx_errors}</div>
                <div>RX Dropped: ${iface.stats.rx_dropped}</div>
                <div>TX Dropped: ${iface.stats.tx_dropped}</div>
            `;

            interfacesContainer.appendChild(div);
        });


        // Network addresses
        const addressesContainer = document.getElementById("addresses");

        addressesContainer.innerHTML = "";

        data.network.connections.addresses.forEach(addr => {
            const div = document.createElement("div");

            div.textContent =
                `${addr.interface}: ${addr.address}/${addr.prefix}`;

            addressesContainer.appendChild(div);
        });


        // Network routes
        const routesContainer = document.getElementById("routes");

        routesContainer.innerHTML = "";

        data.network.connections.routes.forEach(route => {
            const div = document.createElement("div");

            div.textContent =
                `${route.interface}: ${route.destination} → ${route.gateway} (metric ${route.metric})`;

            routesContainer.appendChild(div);
        });

        document.getElementById("connection-status").textContent =
            "Connected";

        document.getElementById("connection-status").className =
            "status connected";

        document.getElementById("last-update").textContent =
            new Date().toLocaleTimeString();

    } catch (error) {
        console.error("API ERROR:", error);

        document.getElementById("connection-status").textContent =
            "Disconnected";

        document.getElementById("connection-status").className =
            "status disconnected";
    }
}

function formatBytes(bytes) {
    const gb = bytes / 1024 / 1024 / 1024;

    if (gb >= 1) {
        return gb.toFixed(2) + " GB";
    }

    const mb = bytes / 1024 / 1024;
    return mb.toFixed(2) + " MB";
}

updateDashboard();

setInterval(updateDashboard, 2000);