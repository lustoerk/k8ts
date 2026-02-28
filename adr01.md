ADR 001 — Kubernetes Distribution (Revised)
Context
Original design chose k3d. Primary risk was FUSE device passthrough for
SeaweedFS CSI — k3d runs containers inside Docker Desktop's Linux VM, making
/dev/fuse availability uncertain on macOS.
Decision
minikube with qemu2 driver.
Rationale
minikube runs a real Linux VM. /dev/fuse exists natively. Eliminates the
highest-risk item from the original design. Single-node is sufficient for all
initial learning targets.
Tradeoffs Accepted

Single-node only initially. Multi-node possible with minikube node add
but less flexible than k3d.
Slightly heavier than k3d (full VM vs containers).
qemu2 driver is slower to start than Docker driver, but avoids the
Docker-in-VM layer that causes FUSE issues.