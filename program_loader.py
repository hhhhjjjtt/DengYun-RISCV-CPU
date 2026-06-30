#!/usr/bin/env python3
"""
program_loader.py — Load firmware into DengYun-1 SoC via USB-UART.

Matches the protocol implemented in rtl/debug/program_loader.v:

  RTS high → i_debug_en=1 → CPU held in reset, loader FSM active.
  RTS low  → i_debug_en=0 → CPU released.

  1. Assert RTS.
  2. Send metadata packet (130 B):
       [firmware_size: 4B LE | zeros: 124B | CRC-16: 2B LE]
     Wait for ACK (0x06).
  3. Send (firmware_size / 128) data packets (130 B each):
       [data: 128B | CRC-16: 2B LE]
     Wait for ACK after each; retry on NAK (0x15), up to MAX_RETRIES.
  4. Deassert RTS.

Firmware blob layout (ROM first, then RAM, each padded to full size with zeros):
  0x00000 .. ROM_SIZE-1         : inst_rom/rom.mem
  ROM_SIZE .. ROM_SIZE+RAM_SIZE-1 : data_ram/ram.mem

CRC-16/IBM: poly=0xA001 (reflected 0x8005), init=0xFFFF, no XorOut.

Usage:
  python program_loader.py COM3 fpga_tests/mem
  python program_loader.py /dev/ttyUSB0 fpga_tests/mem --baud 115200
"""

import argparse
import os
import struct
import sys
import time
import serial

BAUD_RATE   = 115200
PACKET_DATA = 128       # payload bytes per packet
PACKET_SIZE = 130       # payload + 2 CRC bytes
ACK         = 0x06
NAK         = 0x15
MAX_RETRIES = 10
ACK_TIMEOUT = 2.0       # seconds to wait for one-byte ACK/NAK response


# ---------------------------------------------------------------------------
# CRC-16/IBM
# ---------------------------------------------------------------------------

def crc16(data: bytes) -> int:
    """CRC-16/IBM: poly=0xA001 (reflected 0x8005), init=0xFFFF, no XorOut.

    Matches the bit-by-bit hardware implementation in program_loader.v:
        crc_result ^= byte
        8x: if lsb: crc >>= 1, crc ^= 0xA001  else: crc >>= 1
    """
    crc = 0xFFFF
    for b in data:
        crc ^= b
        for _ in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ 0xA001
            else:
                crc >>= 1
    return crc


def build_packet(payload: bytes) -> bytes:
    """Return 130-byte packet: 128-byte payload + CRC-16 little-endian."""
    assert len(payload) == PACKET_DATA
    return payload + struct.pack('<H', crc16(payload))


# ---------------------------------------------------------------------------
# .mem file parser ($readmemh format)
# ---------------------------------------------------------------------------

def parse_mem(path: str, size_bytes: int) -> bytes:
    """Parse a $readmemh hex file into exactly size_bytes (little-endian words).

    Each non-empty, non-comment line is one 32-bit hex word at the current
    address. '@addr' directives set the word address. Unpopulated words are 0.
    Missing files are treated as all zeros (no data section → zeroed RAM).
    """
    n_words = size_bytes // 4
    words   = [0] * n_words
    addr    = 0
    try:
        with open(path) as f:
            for raw in f:
                line = raw.split('//')[0].strip()
                if not line:
                    continue
                if line.startswith('@'):
                    addr = int(line[1:], 16)
                    continue
                for token in line.split():
                    if addr < n_words:
                        words[addr] = int(token, 16)
                    addr += 1
    except FileNotFoundError:
        print(f"  Warning: {path} not found — filling with zeros", file=sys.stderr)
    return b''.join(struct.pack('<I', w) for w in words)


# ---------------------------------------------------------------------------
# Serial helpers
# ---------------------------------------------------------------------------

def send_packet(ser: serial.Serial, packet: bytes, label: str) -> bool:
    """Send one 130-byte packet and wait for ACK. Returns True on ACK."""
    assert len(packet) == PACKET_SIZE
    for attempt in range(1, MAX_RETRIES + 1):
        ser.write(packet)
        ser.flush()
        resp = ser.read(1)
        if not resp:
            print(f"  {label}: timeout waiting for response (attempt {attempt}/{MAX_RETRIES})",
                  file=sys.stderr)
        elif resp[0] == ACK:
            return True
        elif resp[0] == NAK:
            print(f"  {label}: NAK — retrying (attempt {attempt}/{MAX_RETRIES})", file=sys.stderr)
        else:
            print(f"  {label}: unexpected byte 0x{resp[0]:02X} (attempt {attempt}/{MAX_RETRIES})",
                  file=sys.stderr)
    print(f"  {label}: failed after {MAX_RETRIES} retries", file=sys.stderr)
    return False


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    ap = argparse.ArgumentParser(
        description="Load firmware into DengYun-1 SoC via USB-UART (program_loader.v)")
    ap.add_argument('port',
                    help="Serial port (e.g. COM3 or /dev/ttyUSB0)")
    ap.add_argument('mem_dir',
                    help="Directory containing inst_rom/rom.mem and data_ram/ram.mem")
    ap.add_argument('--rom-size', type=lambda x: int(x, 0), default=0x10000,
                    help="ROM size in bytes (default: 0x10000 = 64 KB)")
    ap.add_argument('--ram-size', type=lambda x: int(x, 0), default=0x10000,
                    help="RAM size in bytes (default: 0x10000 = 64 KB)")
    ap.add_argument('--baud', type=int, default=BAUD_RATE,
                    help=f"Baud rate (default: {BAUD_RATE})")
    ap.add_argument('--invert-rts', action='store_true',
                    help="Invert RTS polarity (if adapter inverts i_debug_en)")
    args = ap.parse_args()

    # ---- Build firmware blob ------------------------------------------------
    rom_path = os.path.join(args.mem_dir, 'rom.mem')
    ram_path = os.path.join(args.mem_dir, 'ram.mem')

    print(f"ROM: {rom_path}")
    rom_bytes = parse_mem(rom_path, args.rom_size)
    print(f"RAM: {ram_path}")
    ram_bytes = parse_mem(ram_path, args.ram_size)

    firmware  = rom_bytes + ram_bytes
    fw_size   = len(firmware)
    n_packets = fw_size // PACKET_DATA
    assert fw_size % PACKET_DATA == 0, \
        f"firmware size {fw_size} is not a multiple of {PACKET_DATA}"

    print(f"\nFirmware : {fw_size} bytes ({n_packets} data packets)")
    print(f"Port     : {args.port}  Baud: {args.baud}")

    # ---- Open serial port --------------------------------------------------
    with serial.Serial(args.port, args.baud, timeout=ACK_TIMEOUT) as ser:
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        # Assert RTS → i_debug_en=1 → CPU held in reset, loader FSM starts
        ser.rts = not args.invert_rts
        time.sleep(0.05)            # give FPGA time to see edge and reach ST_WAIT_PACKET

        # ---- Metadata packet -----------------------------------------------
        print("\nSending metadata packet...")
        meta_payload = struct.pack('<I', fw_size) + bytes(PACKET_DATA - 4)
        if not send_packet(ser, build_packet(meta_payload), "metadata"):
            ser.rts = args.invert_rts
            sys.exit("Metadata packet failed — aborting.")
        print("  ACK  (firmware_size=0x{:X})".format(fw_size))

        # ---- Data packets --------------------------------------------------
        print(f"\nSending {n_packets} data packets...")
        t0 = time.time()
        for i in range(n_packets):
            chunk = firmware[i * PACKET_DATA : (i + 1) * PACKET_DATA]
            label = f"pkt {i+1:4d}/{n_packets}  @0x{i * PACKET_DATA:05X}"
            if not send_packet(ser, build_packet(chunk), label):
                ser.rts = not args.invert_rts
                sys.exit(f"Packet {i+1} failed — aborting.")

            done = i + 1
            if done % 64 == 0 or done == n_packets:
                elapsed = time.time() - t0
                rate    = done * PACKET_DATA / elapsed / 1024
                pct     = done * 100 // n_packets
                print(f"  [{pct:3d}%]  {done}/{n_packets} packets  "
                      f"{elapsed:.1f}s  {rate:.1f} KB/s")

        # Deassert RTS → i_debug_en=0 → CPU released from reset
        ser.rts = args.invert_rts
        elapsed = time.time() - t0
        print(f"\nDone in {elapsed:.1f}s. CPU released.")


if __name__ == '__main__':
    main()
