# Direct-Mapped Cache Controller

This repository contains the implementation of a Direct-Mapped Cache Controller  This project focuses on designing a Direct-Mapped Cache Controller using Verilog HDL. The cache controller is designed to efficiently manage memory requests between the CPU and main memory using a direct-mapped caching technique.

This Direct-Mapped Cache has the following specifications:
- Cache Size: 2KB total size with 16-byte cache blocks.
- 32-Bit Addressing: The system uses 32-bit memory addresses.
- Byte-Addressable: The memory is byte-addressable.
- Read/Write Policies:
  - Write Miss: Write-Allocate (Write and Allocate)
  - Write Hit: Write-Through (Direct Write)
- Ready-Valid Handshake Protocol: Ensures synchronization between CPU, Cache, and Main Memory.
- Cache Performance Metrics:
  - Cache Hits and Misses: Counted using dedicated counters.
  - Hit Rate Calculation: Automatically calculated.

The cache is direct-mapped, meaning each memory address maps to exactly one cache line. A total of 128 cache lines are used, each with 16 bytes of data. The memory is divided as follows:
- Tag: Identifies the memory block in the cache.
- Index: Selects the cache line.
- Offset: Specifies the exact byte within the cache line.

When the CPU requests a memory read or write:
- The address is divided into Tag, Index, and Offset.
- If the requested block is in the cache (Cache Hit), it is directly read or written.
- If the block is not in the cache (Cache Miss), it is fetched from the main memory and placed in the cache.
- Write requests follow the Write-Allocate policy for misses and Write-Through policy for hits.

### Simulation and Testing
The Verilog code (onbellek.v) is tested using a dedicated testbench. Cache performance is measured using two counters:
- `sayac_bulamama` (Miss Counter): Counts the number of cache misses.
- `sayac_erisim` (Access Counter): Counts the total number of cache accesses.

The final hit rate is calculated as:

Hit Rate = (1 - sayac_bulamama / sayac_erisim) * 100%

Test scenarios include:
- Cache-enabled and cache-disabled modes are compared.
- Special programs are used to demonstrate high or low hit rates.
- Performance optimizations are discussed in the report.

### Usage Instructions
1. Open the project in your Verilog simulation environment (e.g., Xilinx Vivado).
2. Set onbellek.v as the top module.
3. Run the simulation and observe the console outputs for cache performance metrics.

This project includes:
- Verilog Code (onbellek.v) for the Direct-Mapped Cache Controller.
- Synthesis Report (onbellek.vds) showing synthesis details.
- A Project Report (rapor.pdf) explaining the design, testing, and performance.

### Performance Optimization
The report discusses various strategies to improve cache performance, including:
- Increasing cache size.
- Adjusting block size for better spatial locality.
- Exploring other cache mapping techniques (e.g., set-associative).

### Challenges and Solutions
During the development of this project, the following challenges were encountered:
- Cache Miss Calculation: Accurately counting hits and misses without double counting.
- Memory Synchronization: Correctly implementing the Ready-Valid Handshake protocol for CPU and Main Memory communication.
- Timing Issues: Ensuring that all read and write operations occur at the correct clock cycles.

These challenges were overcome through careful design, testing, and optimization of the Verilog code.
