## MacStadium + Jenkins Workers

The current setup for macOS workers uses MacStadium as a platform to deploy them
to. They offer support for vSphere which we use together with Terraform's vSphere
Provider for setting up hosts.

Once signed up with MacStadium, you're receive all the neccessary details. These
include:
- Connection details to VPN for accessing the vSphere instance
- IP Allocations
- Dashboard credentials for accessing the vSphere Online GUI after connecting
to VPN

Most components are manually created right now. These include:

- Initial macOS template from which instances will be created from. The template have
most software manually installed, which the template is then created from.
- Everytime a change happens, manual connection to the instance must happen, software
installed/changed and then creation of a new template happens. Once template exists,
the Terraform configuration should reference the new template, and instances recreated.
- DHCP server manually setup and configured to give the macOS instances IP addresses.
This is currently a Debian server running isc-dhcp-server, with the IP allocation
received defined in the default configuration
