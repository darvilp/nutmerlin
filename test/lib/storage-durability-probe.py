#!/usr/bin/env python3
import os
import sys

operation, root = sys.argv[1:3]
if os.environ.get("NUTMERLIN_TEST_DURABILITY_FAILURE") == operation:
    raise OSError("injected durability failure")

def fsync_directory():
    descriptor = os.open(root, os.O_RDONLY)
    os.fsync(descriptor)
    os.close(descriptor)

if operation == "file-fsync":
    descriptor = os.open(os.path.join(root, "fsync-file"), os.O_CREAT | os.O_WRONLY, 0o600)
    os.write(descriptor, b"sealed\n")
    os.fsync(descriptor)
    os.close(descriptor)
elif operation == "directory-fsync":
    fsync_directory()
elif operation == "interruption-recovery":
    active, candidate = os.path.join(root, "active"), os.path.join(root, "candidate")
    with open(active, "wb") as stream:
        stream.write(b"generation-a\n"); stream.flush(); os.fsync(stream.fileno())
    fsync_directory()
    for phase, expected in (("before-rename", b"generation-a\n"), ("after-rename", b"generation-b\n")):
        child = os.fork()
        if child == 0:
            with open(candidate, "wb") as stream:
                stream.write(b"generation-b\n"); stream.flush(); os.fsync(stream.fileno())
            if phase == "after-rename": os.replace(candidate, active); fsync_directory()
            os.kill(os.getpid(), 9)
        os.waitpid(child, 0)
        assert open(active, "rb").read() == expected
        if os.path.exists(candidate): os.unlink(candidate)
else:
    raise ValueError("unknown durability probe")
