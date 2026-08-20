package system

import "core:sys/linux"

Disk_Stats :: struct {
    total: u64,
    free:  u64,
    used:  u64,
}

get_disk_stats :: proc(path: cstring = "/") -> (Disk_Stats) {
    fs: linux.Stat_FS

    err := linux.statfs(path, &fs)
    if err != linux.Errno(0) {
        return {}
    }

    block_size := u64(fs.bsize)

    total := u64(fs.blocks) * block_size
    free  := u64(fs.bavail) * block_size
    used  := total - free

    return Disk_Stats{
        total = total,
        free  = free,
        used  = used,
    }
}