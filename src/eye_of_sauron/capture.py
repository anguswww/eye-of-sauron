'''Capture module. Handles capturing and processing packets.'''

from scapy.all import AsyncSniffer

def handle_packet(packet):
    # implement properly later, need flow tracker to be implemented first.
    # flow_tracker.add(packet)
    pass


sniffer = AsyncSniffer(
    iface="eth1",
    filter="ip",
    prn=handle_packet,
    store=False,
)

sniffer.start()